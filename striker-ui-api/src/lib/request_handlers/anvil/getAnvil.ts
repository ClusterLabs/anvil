import { RequestHandler } from 'express';

import { DELETED } from '../../consts';

import buildGetRequestHandler from '../buildGetRequestHandler';
import buildQueryAnvilDetail from './buildQueryAnvilDetail';
import { buildQueryResultModifier } from '../../buildQueryResultModifier';
import { getShortHostName } from '../../disassembleHostName';
import { sanitize } from '../../sanitize';

export const getAnvil: RequestHandler = buildGetRequestHandler(
  (request, hooks) => {
    const { anvilUUIDs, isForProvisionServer } = request.query;

    let sql = `
      SELECT
        a.anvil_name,
        a.anvil_uuid,
        a.anvil_description,
        b.host_name,
        b.host_uuid,
        b.host_type,
        b.host_status,
        CASE
          WHEN c.scan_cluster_node_cluster_member
            THEN 'cluster_member'
          WHEN c.scan_cluster_node_crmd_member
            THEN 'crmd_member'
          WHEN c.scan_cluster_node_in_ccm
            THEN 'in_ccm'
          ELSE 'not_member'
        END AS host_cluster_membership,
        d.scan_drbd_resource_uuid,
        d.scan_drbd_resource_name,
        f.scan_drbd_peer_connection_state,
        f.scan_drbd_peer_local_disk_state,
        f.scan_drbd_peer_estimated_time_to_sync
      FROM anvils AS a
      JOIN hosts AS b
        ON b.host_uuid IN (
          a.anvil_node1_host_uuid,
          a.anvil_node2_host_uuid
        )
      JOIN scan_cluster_nodes AS c
        ON c.scan_cluster_node_host_uuid = b.host_uuid
      LEFT JOIN scan_drbd_resources AS d
        ON d.scan_drbd_resource_host_uuid = b.host_uuid
          AND d.scan_drbd_resource_xml != '${DELETED}'
      LEFT JOIN scan_drbd_volumes AS e
        ON e.scan_drbd_volume_scan_drbd_resource_uuid = d.scan_drbd_resource_uuid
          AND e.scan_drbd_volume_device_path != '${DELETED}'
      LEFT JOIN scan_drbd_peers AS f
        ON f.scan_drbd_peer_scan_drbd_volume_uuid = e.scan_drbd_volume_uuid
          AND f.scan_drbd_peer_connection_state != '${DELETED}'
      ORDER BY
        a.anvil_name ASC,
        b.host_name ASC,
        d.scan_drbd_resource_name ASC;`;

    let afterQueryReturn: QueryResultModifierFunction | undefined =
      buildQueryResultModifier<AnvilOverview[]>((rows) => {
        let anvilStage: AnvilOverview | undefined;
        let hostsStage: Record<string, AnvilOverviewHost> = {};

        const result = rows.reduce<AnvilOverview[]>(
          (
            previous,
            [
              anvilName,
              anvilUUID,
              anvilDescription,
              hostName,
              hostUUID,
              hostType,
              hostStatus,
              hostClusterMembership,
              hostDrbdResourceUuid,
              hostDrbdResourceName,
              hostDrbdResourceConnectionState,
              hostDrbdResourceLocalDiskState,
              hostDrbdResourceEstimatedTimeToSync,
            ],
            index,
          ) => {
            if (anvilUUID !== anvilStage?.anvilUUID) {
              // Init the stages when the anvil is first seen

              anvilStage = {
                anvilDescription,
                anvilName,
                anvilStatus: {
                  drbd: {
                    status: '',
                    maxEstimatedTimeToSync: 0,
                  },
                  system: '',
                },
                anvilUUID,
                hosts: [],
              };

              hostsStage = {};

              previous.push(anvilStage);
            }

            if (!hostsStage[hostUUID]) {
              hostsStage[hostUUID] = {
                hostClusterMembership,
                hostDrbdResources: {},
                hostName,
                hostStatus,
                hostType,
                hostUUID,
                shortHostName: getShortHostName(hostName),
              };

              anvilStage.hosts.push(hostsStage[hostUUID]);
            }

            if (hostDrbdResourceUuid) {
              hostsStage[hostUUID].hostDrbdResources[hostDrbdResourceUuid] = {
                connection: {
                  state: hostDrbdResourceConnectionState,
                },
                name: hostDrbdResourceName,
                replication: {
                  state: hostDrbdResourceLocalDiskState,
                  estimatedTimeToSync: Number(
                    hostDrbdResourceEstimatedTimeToSync,
                  ),
                },
                uuid: hostDrbdResourceUuid,
              };
            }

            const next = rows[index + 1];

            if (!next || next[1] !== anvilStage.anvilUUID) {
              // Summarize when finished with an anvil's rows

              let allClusterMember = true;
              let allOffline = true;

              let allReplicationOffline = true;
              let allReplicationUpToDate = true;

              let oneConnectionDisconnected = false;
              let oneReplicationSyncTarget = false;

              let noResources = false;

              let maxReplicationEstimatedTimeToSync = 0;

              anvilStage.hosts.forEach((host) => {
                allClusterMember =
                  allClusterMember &&
                  host.hostClusterMembership === 'cluster_member';

                allOffline = allOffline && host.hostStatus === 'offline';

                const drbdResources = Object.values(host.hostDrbdResources);

                noResources = !drbdResources.length;

                drbdResources.forEach((resource) => {
                  allReplicationUpToDate =
                    allReplicationUpToDate &&
                    resource.replication.state === 'uptodate';

                  allReplicationOffline =
                    allReplicationOffline &&
                    resource.replication.state === 'off';

                  oneConnectionDisconnected =
                    oneConnectionDisconnected ||
                    ['standalone', 'unconnected'].includes(
                      resource.connection.state,
                    );

                  oneReplicationSyncTarget =
                    oneReplicationSyncTarget ||
                    resource.replication.state === 'synctarget';

                  maxReplicationEstimatedTimeToSync = Math.max(
                    maxReplicationEstimatedTimeToSync,
                    resource.replication.estimatedTimeToSync,
                  );
                });
              });

              if (allOffline) {
                anvilStage.anvilStatus.system = 'offline';
              } else if (allClusterMember) {
                anvilStage.anvilStatus.system = 'optimal';
              } else {
                anvilStage.anvilStatus.system = 'degraded';
              }

              if (noResources) {
                anvilStage.anvilStatus.drbd.status = 'none';
              } else if (allReplicationOffline) {
                anvilStage.anvilStatus.drbd.status = 'offline';
              } else if (oneReplicationSyncTarget) {
                anvilStage.anvilStatus.drbd = {
                  status: 'syncing',
                  maxEstimatedTimeToSync: maxReplicationEstimatedTimeToSync,
                };
              } else if (allReplicationUpToDate) {
                anvilStage.anvilStatus.drbd.status = 'optimal';
              } else {
                anvilStage.anvilStatus.drbd.status = 'degraded';
              }
            }

            return previous;
          },
          [],
        );

        return result;
      });

    if (anvilUUIDs) {
      ({ query: sql, afterQueryReturn } = buildQueryAnvilDetail({
        anvilUUIDs: sanitize(anvilUUIDs, 'string[]', {
          modifierType: 'sql',
        }),
        isForProvisionServer: sanitize(isForProvisionServer, 'boolean'),
      }));
    }

    hooks.afterQueryReturn = afterQueryReturn;

    return sql;
  },
);
