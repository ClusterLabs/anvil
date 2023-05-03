import assert from 'assert';
import { RequestHandler } from 'express';

import { getAnvilData, getHostData, query } from '../../accessModule';
import { stderr } from '../../shell';

const buildHostStateMessage = (postfix = 2) => `message_022${postfix}`;

export const getAnvilDetail: RequestHandler<
  AnvilDetailParamsDictionary,
  AnvilDetailResponseBody,
  undefined
> = async (request, response) => {
  const {
    params: { anvilUuid },
  } = request;

  let anvils: AnvilDataAnvilListHash;
  let hosts: AnvilDataHostListHash;

  try {
    anvils = await getAnvilData();
    hosts = await getHostData();
  } catch (error) {
    stderr(`Failed to get anvil and/or host data; CAUSE: ${error}`);

    return response.status(500).send();
  }

  const {
    anvil_uuid: {
      [anvilUuid]: {
        anvil_node1_host_uuid: n1uuid,
        anvil_node2_host_uuid: n2uuid,
      },
    },
  } = anvils;

  const result: AnvilDetailResponseBody = { anvil_state: 'optimal', hosts: [] };

  for (const huuid of [n1uuid, n2uuid]) {
    const {
      host_uuid: {
        [huuid]: { host_status: hstatus, short_host_name: hname },
      },
    } = hosts;

    const { hosts: rhosts } = result;

    const hsummary: AnvilDetailHostSummary = {
      host_name: hname,
      host_uuid: huuid,
      maintenance_mode: false,
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
      stderr(`Failed to get node ${huuid} cluster status; CAUSE: ${error}`);

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

  response.status(200).send(result);
};
