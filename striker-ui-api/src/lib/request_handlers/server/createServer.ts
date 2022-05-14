import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { dbQuery, sub } from '../../accessModule';

export const createServer: RequestHandler = ({ body }, response) => {
  console.log('Creating server.');

  if (body) {
    const {
      serverName,
      cpuCores,
      memory,
      virtualDisks: [
        { storageSize = undefined, storageGroupUUID = undefined } = {},
      ] = [],
      installISOFileUUID,
      driverISOFileUUID = 'none',
      anvilUUID,
      optimizeForOS,
    } = body;

    console.dir(body, { depth: null });

    const provisionServerJobData = `server_name=${serverName}
os=${optimizeForOS}
cpu_cores=${cpuCores}
ram=${memory}
storage_group_uuid=${storageGroupUUID}
storage_size=${storageSize}
install_iso=${installISOFileUUID}
driver_iso=${driverISOFileUUID}`;

    console.log(`provisionServerJobData: [${provisionServerJobData}]`);

    const [[provisionServerJobHostUUID]] = dbQuery(
      `SELECT
          CASE
            WHEN pri_hos.primary_host_uuid IS NULL
              THEN nod_1.node1_host_uuid
            ELSE pri_hos.primary_host_uuid
          END AS host_uuid
        FROM (
          SELECT
            1 AS phl,
            sca_clu_nod.scan_cluster_node_host_uuid AS primary_host_uuid
          FROM anvils AS anv
          JOIN scan_cluster_nodes AS sca_clu_nod
            ON sca_clu_nod.scan_cluster_node_host_uuid = anv.anvil_node1_host_uuid
              OR sca_clu_nod.scan_cluster_node_host_uuid = anv.anvil_node2_host_uuid
          WHERE sca_clu_nod.scan_cluster_node_in_ccm
            AND sca_clu_nod.scan_cluster_node_crmd_member
            AND sca_clu_nod.scan_cluster_node_cluster_member
            AND (NOT sca_clu_nod.scan_cluster_node_maintenance_mode)
            AND anv.anvil_uuid = '${anvilUUID}'
          ORDER BY sca_clu_nod.scan_cluster_node_name
          LIMIT 1
        ) AS pri_hos
        RIGHT JOIN (
          SELECT
            1 AS phr,
            anv.anvil_node1_host_uuid AS node1_host_uuid
          FROM anvils AS anv
          WHERE anv.anvil_uuid = '${anvilUUID}'
        ) AS nod_1
          ON pri_hos.phl = nod_1.phr;`,
    ).stdout;

    console.log(`provisionServerJobHostUUID: [${provisionServerJobHostUUID}]`);

    sub('insert_or_update_jobs', {
      subParams: {
        file: __filename,
        line: 0,
        job_command: SERVER_PATHS.usr.sbin['anvil-provision-server'].self,
        job_data: provisionServerJobData,
        job_name: 'server:provision',
        job_title: 'job_0147',
        job_description: 'job_0148',
        job_progress: 0,
        job_host_uuid: provisionServerJobHostUUID,
      },
    });
  }

  response.status(202).send();
};
