import { queries } from '../../accessModule';
import { perr } from '../../shell';
import {
  sqlHosts,
  sqlScanClusterNodes,
  sqlScanDrbdPeers,
  sqlScanDrbdResources,
  sqlScanDrbdVolumes,
  sqlServers,
} from '../../sqls';

const buildHostStateMessage = (postfix = 2) => `message_022${postfix}`;

export const buildAnvilSummary = async ({
  anvils: nodeList,
  anvilUuid,
}: {
  anvils: AnvilDataAnvilListHash;
  anvilUuid: string;
}) => {
  const {
    anvil_uuid: { [anvilUuid]: anvilData },
  } = nodeList;

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
        maxEstimatedTimeToSync: 0,
        status: 'none',
      },
      system: '',
    },
    anvil_name: anvilName,
    anvil_uuid: anvilUuid,
    hosts: [],
  };

  const sqlGetHostServerCount = `
    SELECT
      b.host_uuid,
      b.host_short_name,
      b.host_status,
      COUNT(c.server_uuid) AS number_of_servers
    FROM anvils AS a
    LEFT JOIN (${sqlHosts()}) AS b
      ON b.host_uuid IN (
        a.anvil_node1_host_uuid,
        a.anvil_node2_host_uuid
      )
    LEFT JOIN (
      ${sqlServers()} AND server_state = 'running'
    ) AS c
      ON c.server_host_uuid = b.host_uuid
    WHERE a.anvil_uuid = '${anvilUuid}'
    GROUP BY
      b.host_uuid,
      b.host_short_name,
      b.host_status
    ORDER BY b.host_short_name;`;

  const sqlGetHostClusterFlags = `
    SELECT
      a.scan_cluster_node_host_uuid,
      a.scan_cluster_node_in_ccm,
      a.scan_cluster_node_crmd_member,
      a.scan_cluster_node_cluster_member,
      a.scan_cluster_node_maintenance_mode
    FROM (${sqlScanClusterNodes()}) AS a
    WHERE a.scan_cluster_node_host_uuid IN (
      '${subnode1Uuid}',
      '${subnode2Uuid}'
    );`;

  const sqlGetHostDrbdResources = `
    SELECT
      a.scan_drbd_resource_host_uuid,
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
    WHERE a.scan_drbd_resource_host_uuid IN (
      '${subnode1Uuid}',
      '${subnode2Uuid}'
    );`;

  const sqlGetNodeStatus = `
    SELECT
      COUNT(a.host_uuid) AS number_of_hosts,
      SUM(
        CAST(a.host_status = 'offline' AS int)
      ) AS host_offline,
      SUM(
        CAST(b.scan_cluster_node_cluster_member AS int)
      ) AS host_cluster_member
    FROM (${sqlHosts()}) AS a
    JOIN (${sqlScanClusterNodes()}) AS b
      ON b.scan_cluster_node_host_uuid = a.host_uuid
    WHERE a.host_uuid IN (
      '${subnode1Uuid}',
      '${subnode2Uuid}'
    );`;

  const sqlGetNodeDrbdSummary = `
    SELECT
      COUNT(a.scan_drbd_peer_uuid) AS number_of_peers,
      SUM(
        CAST(a.scan_drbd_peer_connection_state = 'off' AS int)
      ) AS connection_off,
      SUM(
        CAST(a.scan_drbd_peer_local_disk_state = 'uptodate' AS int)
      ) AS local_disk_uptodate,
      SUM(
        CAST(a.scan_drbd_peer_disk_state = 'uptodate' AS int)
      ) AS peer_disk_uptodate,
      MAX(
        a.scan_drbd_peer_estimated_time_to_sync
      ) AS max_estimated_time_to_sync
    FROM (${sqlScanDrbdPeers()}) AS a
    WHERE a.scan_drbd_peer_host_uuid IN (
      '${subnode1Uuid}',
      '${subnode2Uuid}'
    );`;

  let results: QueryResult[];

  try {
    results = await queries(
      sqlGetHostServerCount,
      sqlGetHostClusterFlags,
      sqlGetHostDrbdResources,
      sqlGetNodeStatus,
      sqlGetNodeDrbdSummary,
    );
  } catch (error) {
    perr(`Failed to get node summary data; CAUSE: ${error}`);

    throw error;
  }

  const hosts: Record<string, AnvilDetailHostSummary> = {};

  const [
    hostRows,
    hostClusterFlagRows,
    hostDrbdResourceRows,
    nodeStatusRows,
    nodeDrbdSummaryRows,
  ] = results;

  hostRows.forEach((row) => {
    const [uuid, short, status, count] = row as [
      string,
      string,
      string,
      number,
    ];

    hosts[uuid] = {
      hostDrbdResources: {},
      host_name: short,
      host_uuid: uuid,
      maintenance_mode: false,
      server_count: count,
      state: status,
      state_message: '',
      state_percent: 0,
    };
  });

  hostClusterFlagRows.forEach((row) => {
    const [uuid, ccm, crmd, cluster, maintenance] = row as [
      string,
      ...number[]
    ];

    const { [uuid]: host } = hosts;

    if (!host) {
      return;
    }

    host.maintenance_mode = Boolean(maintenance);

    if (cluster) {
      host.state = 'online';
      host.state_message = buildHostStateMessage(3);
      host.state_percent = 100;
    } else if (crmd) {
      host.state = 'crmd';
      host.state_message = buildHostStateMessage(4);
      host.state_percent = 75;
    } else if (ccm) {
      host.state = 'in_ccm';
      host.state_message = buildHostStateMessage(5);
      host.state_percent = 50;
    } else {
      host.state = 'booted';
      host.state_message = buildHostStateMessage(6);
      host.state_percent = 25;
    }
  });

  hostDrbdResourceRows.forEach((row) => {
    const [
      hostUuid,
      resourceUuid,
      resourceName,
      resourceConnectionState,
      resourceLocalDiskState,
      resourceEstimatedTimeToSync,
    ] = row as [string, string, string, string, string, number];

    const { [hostUuid]: host } = hosts;

    if (!host) {
      return;
    }

    host.hostDrbdResources[resourceUuid] = {
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

  result.hosts = Object.values(hosts);

  nodeStatusRows.forEach((row) => {
    const [numHosts, numOffline, numClusterMember] = row as number[];

    if (numOffline === numHosts) {
      result.anvilStatus.system = 'offline';
    } else if (numClusterMember === numHosts) {
      result.anvilStatus.system = 'optimal';
    } else {
      result.anvilStatus.system = 'degraded';
    }
  });

  nodeDrbdSummaryRows.forEach((row) => {
    const [
      numPeers,
      numConnectionOff,
      numLocalDiskUptodate,
      numPeerDiskUptodate,
      maxEstimatedTimeToSync,
    ] = row as number[];

    if (!numPeers) {
      // No peer(s) found, default to 'none'
      return;
    }

    if (numConnectionOff === numPeers) {
      // All peer records have connection state as off
      result.anvilStatus.drbd.status = 'offline';
    } else if (maxEstimatedTimeToSync > 0) {
      // At least 1 peer record has time-to-sync
      result.anvilStatus.drbd = {
        maxEstimatedTimeToSync,
        status: 'syncing',
      };
    } else if (numLocalDiskUptodate + numPeerDiskUptodate === numPeers * 2) {
      // All peer records have local and peer disk state as uptodate
      result.anvilStatus.drbd.status = 'optimal';
    } else {
      // Degraded happens when at least 1 resource:
      // - doesn't have "established" as connection state
      // - OR local disk state is "unknown"
      result.anvilStatus.drbd.status = 'degraded';
    }
  });

  return result;
};
