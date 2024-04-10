import assert from 'assert';

import { query } from '../../accessModule';
import { perr } from '../../shell';

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
    anvil_uuid: { [anvilUuid]: ainfo },
  } = anvils;

  if (!ainfo)
    throw new Error(`Anvil information not found with UUID ${anvilUuid}`);

  const {
    anvil_name: aname,
    anvil_node1_host_uuid: n1uuid,
    anvil_node2_host_uuid: n2uuid,
  } = ainfo;

  const result: AnvilDetailSummary = {
    anvil_name: aname,
    anvil_state: 'optimal',
    anvil_uuid: anvilUuid,
    hosts: [],
  };

  let scounts: [scount: number, hostUuid: string][];

  try {
    scounts = await query(
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

  for (const huuid of [n1uuid, n2uuid]) {
    const {
      host_uuid: {
        [huuid]: { host_status: hstatus, short_host_name: hname },
      },
    } = hosts;

    const { hosts: rhosts } = result;

    const found = scounts.find((row) => {
      if (row.length !== 2) return false;

      const { 1: uuid } = row;

      return uuid === huuid;
    });

    const scount = found ? found[0] : 0;

    const hsummary: AnvilDetailHostSummary = {
      host_name: hname,
      host_uuid: huuid,
      maintenance_mode: false,
      server_count: scount,
      state: 'offline',
      state_message: buildHostStateMessage(),
      state_percent: 0,
    };

    rhosts.push(hsummary);

    if (hstatus !== 'online') continue;

    let rows: [
      inCcm: NumberBoolean,
      crmdMember: NumberBoolean,
      clusterMember: NumberBoolean,
      maintenanceMode: NumberBoolean,
    ][];

    try {
      rows = await query(`SELECT
                            scan_cluster_node_in_ccm,
                            scan_cluster_node_crmd_member,
                            scan_cluster_node_cluster_member,
                            scan_cluster_node_maintenance_mode
                          FROM
                            scan_cluster_nodes
                          WHERE
                            scan_cluster_node_host_uuid = '${huuid}';`);

      assert.ok(rows.length, 'No node cluster info');
    } catch (error) {
      perr(`Failed to get node ${huuid} cluster status; CAUSE: ${error}`);

      continue;
    }

    const [[ccm, crmd, cluster, maintenance]] = rows;

    hsummary.maintenance_mode = Boolean(maintenance);

    if (cluster) {
      hsummary.state = 'online';
      hsummary.state_message = buildHostStateMessage(3);
      hsummary.state_percent = 100;
    } else if (crmd) {
      hsummary.state = 'crmd';
      hsummary.state_message = buildHostStateMessage(4);
      hsummary.state_percent = 75;
    } else if (ccm) {
      hsummary.state = 'in_ccm';
      hsummary.state_message = buildHostStateMessage(5);
      hsummary.state_percent = 50;
    } else {
      hsummary.state = 'booted';
      hsummary.state_message = buildHostStateMessage(6);
      hsummary.state_percent = 25;
    }
  }

  return result;
};
