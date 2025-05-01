import assert from 'assert';

import { DELETED } from '../../consts';

import { query } from '../../accessModule';
import { perr } from '../../shell';
import {
  sqlScanDrbdPeers,
  sqlScanDrbdResources,
  sqlScanDrbdVolumes,
} from '../../sqls';

const buildHostStateMessage = (postfix = 2) => `message_022${postfix}`;

export const buildAnvilSummary = async ({
  anvils,
  anvilUuid,
  hosts,
}: {
  anvils: AnvilDataAnvilListHash;
  anvilUuid: string;
  hosts: AnvilDataHostListHash;
}) => {
  const {
    anvil_uuid: { [anvilUuid]: anvilData },
  } = anvils;

  if (!anvilData)
    throw new Error(`Anvil information not found with UUID ${anvilUuid}`);

  const {
    anvil_name: anvilName,
    anvil_node1_host_uuid: subnode1Uuid,
    anvil_node2_host_uuid: subnode2Uuid,
  } = anvilData;

  const result: AnvilDetailSummary = {
    anvilStatus: {
      drbd: {
        status: '',
        maxEstimatedTimeToSync: 0,
      },
      system: '',
    },
    anvil_name: anvilName,
    anvil_uuid: anvilUuid,
    hosts: [],
  };

  let serverCounts: [scount: number, hostUuid: string][];

  try {
    serverCounts = await query(
      `SELECT
          COUNT(a.server_name),
          b.host_uuid
        FROM servers AS a
        JOIN hosts AS b
          ON a.server_host_uuid = b.host_uuid
        JOIN anvils AS c
          ON b.host_uuid IN (
            c.anvil_node1_host_uuid,
            c.anvil_node2_host_uuid
          )
        WHERE c.anvil_uuid = '${anvilUuid}'
          AND a.server_state = 'running'
        GROUP BY b.host_uuid, b.host_name
        ORDER BY b.host_name;`,
    );
  } catch (error) {
    perr(`Failed to get subnodes' server count; CAUSE: ${error}`);

    throw error;
  }

  for (const hostUuid of [subnode1Uuid, subnode2Uuid]) {
    const {
      host_uuid: {
        [hostUuid]: { host_status: hostStatus, short_host_name: shortHostName },
      },
    } = hosts;

    const found = serverCounts.find((row) => {
      if (row.length !== 2) return false;

      const { 1: serverHostUuid } = row;

      return serverHostUuid === hostUuid;
    });

    const serverCount = found ? found[0] : 0;

    const hostSummary: AnvilDetailHostSummary = {
      hostDrbdResources: {},
      host_name: shortHostName,
      host_uuid: hostUuid,
      maintenance_mode: false,
      server_count: serverCount,
      state: 'offline',
      state_message: buildHostStateMessage(),
      state_percent: 0,
    };

    result.hosts.push(hostSummary);

    // Skip when host isn't online
    if (hostStatus !== 'online') continue;

    let clusterFlags: [
      inCcm: NumberBoolean,
      crmdMember: NumberBoolean,
      clusterMember: NumberBoolean,
      maintenanceMode: NumberBoolean,
    ][];

    try {
      clusterFlags = await query(
        `SELECT
            a.scan_cluster_node_in_ccm,
            a.scan_cluster_node_crmd_member,
            a.scan_cluster_node_cluster_member,
            a.scan_cluster_node_maintenance_mode
          FROM
            scan_cluster_nodes AS a
          JOIN scan_cluster AS a2
            ON a.scan_cluster_node_scan_cluster_uuid = a2.scan_cluster_uuid
              AND a2.scan_cluster_cib != '${DELETED}'
          WHERE a.scan_cluster_node_host_uuid = '${hostUuid}';`,
      );

      assert.ok(clusterFlags.length, 'No subnode cluster info');
    } catch (error) {
      perr(`Failed to get subnode ${hostUuid} cluster status; CAUSE: ${error}`);

      continue;
    }

    const [[ccm, crmd, cluster, maintenance]] = clusterFlags;

    hostSummary.maintenance_mode = Boolean(maintenance);

    if (cluster) {
      hostSummary.state = 'online';
      hostSummary.state_message = buildHostStateMessage(3);
      hostSummary.state_percent = 100;
    } else if (crmd) {
      hostSummary.state = 'crmd';
      hostSummary.state_message = buildHostStateMessage(4);
      hostSummary.state_percent = 75;
    } else if (ccm) {
      hostSummary.state = 'in_ccm';
      hostSummary.state_message = buildHostStateMessage(5);
      hostSummary.state_percent = 50;
    } else {
      hostSummary.state = 'booted';
      hostSummary.state_message = buildHostStateMessage(6);
      hostSummary.state_percent = 25;
    }

    let drbdResources: [
      uuid: string,
      name: string,
      connectionState: string,
      localDiskState: string,
      estimatedTimeToSync: string,
    ][];

    try {
      drbdResources = await query(
        `SELECT
            a.scan_drbd_resource_uuid,
            a.scan_drbd_resource_name,
            c.scan_drbd_peer_connection_state,
            c.scan_drbd_peer_local_disk_state,
            c.scan_drbd_peer_estimated_time_to_sync
          FROM (${sqlScanDrbdResources()}) AS a
          LEFT JOIN (${sqlScanDrbdVolumes()}) AS b
            ON b.scan_drbd_volume_scan_drbd_resource_uuid = a.scan_drbd_resource_uuid
          LEFT JOIN (${sqlScanDrbdPeers()}) AS c
            ON c.scan_drbd_peer_scan_drbd_volume_uuid = b.scan_drbd_volume_uuid
          WHERE a.scan_drbd_resource_host_uuid = '${hostUuid}';`,
      );

      assert.ok(drbdResources.length, 'No subnode DRBD resources');
    } catch (error) {
      continue;
    }

    drbdResources.forEach((resource) => {
      const [
        resourceUuid,
        resourceName,
        resourceConnectionState,
        resourceLocalDiskState,
        resourceEstimatedTimeToSync,
      ] = resource;

      if (!resourceUuid) return;

      hostSummary.hostDrbdResources[resourceUuid] = {
        connection: {
          state: resourceConnectionState,
        },
        name: resourceName,
        replication: {
          state: resourceLocalDiskState,
          estimatedTimeToSync: Number(resourceEstimatedTimeToSync),
        },
        uuid: resourceUuid,
      };
    });
  }

  // Summarize when finished with gathering info on the subnodes

  let allClusterMember = true;
  let allOffline = true;

  let allReplicationOffline = true;
  let allReplicationUpToDate = true;

  let oneConnectionDisconnected = false;
  let oneReplicationSyncTarget = false;

  let noResources = false;

  let maxReplicationEstimatedTimeToSync = 0;

  result.hosts.forEach((host) => {
    allClusterMember = allClusterMember && host.state === 'online';

    allOffline = allOffline && host.state === 'offline';

    const drbdResources = Object.values(host.hostDrbdResources);

    noResources = !drbdResources.length;

    drbdResources.forEach((resource) => {
      allReplicationUpToDate =
        allReplicationUpToDate && resource.replication.state === 'uptodate';

      allReplicationOffline =
        allReplicationOffline && resource.replication.state === 'off';

      oneConnectionDisconnected =
        oneConnectionDisconnected ||
        ['standalone', 'unconnected'].includes(resource.connection.state);

      oneReplicationSyncTarget =
        oneReplicationSyncTarget || resource.replication.state === 'synctarget';

      maxReplicationEstimatedTimeToSync = Math.max(
        maxReplicationEstimatedTimeToSync,
        resource.replication.estimatedTimeToSync,
      );
    });
  });

  if (allOffline) {
    result.anvilStatus.system = 'offline';
  } else if (allClusterMember) {
    result.anvilStatus.system = 'optimal';
  } else {
    result.anvilStatus.system = 'degraded';
  }

  if (noResources) {
    result.anvilStatus.drbd.status = 'none';
  } else if (allReplicationOffline) {
    result.anvilStatus.drbd.status = 'offline';
  } else if (oneReplicationSyncTarget) {
    result.anvilStatus.drbd = {
      status: 'syncing',
      maxEstimatedTimeToSync: maxReplicationEstimatedTimeToSync,
    };
  } else if (allReplicationUpToDate) {
    result.anvilStatus.drbd.status = 'optimal';
  } else {
    result.anvilStatus.drbd.status = 'degraded';
  }

  return result;
};
