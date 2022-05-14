import assert from 'assert';
import { RequestHandler } from 'express';

import { OS_LIST_MAP } from '../../consts/OS_LIST';
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
      driverISOFileUUID,
      anvilUUID,
      optimizeForOS,
    } = body;

    console.dir(body, { depth: null });

    const rgHex = '[0-9a-f]';
    const patternInteger = /^\d+$/;
    const patterUUID = new RegExp(
      `^${rgHex}{8}-${rgHex}{4}-[1-5]${rgHex}{3}-[89ab]${rgHex}{3}-${rgHex}{12}$`,
      'i',
    );

    const dataServerName = String(serverName);
    const dataOS = String(optimizeForOS);
    const dataCPUCores = String(cpuCores);
    const dataRAM = String(memory);
    const dataStorageGroupUUID = String(storageGroupUUID);
    const dataStorageSize = String(storageSize);
    const dataInstallISO = String(installISOFileUUID);
    const dataDriverISO = String(driverISOFileUUID) || 'none';
    const dataAnvilUUID = String(anvilUUID);

    try {
      assert(
        /^[0-9a-z_-]+$/i.test(dataServerName),
        `Data server name can only contain alphanumeric, underscore, and hyphen characters; got [${dataServerName}].`,
      );

      const [[serverNameCount]] = dbQuery(
        `SELECT COUNT(server_uuid) FROM servers WHERE server_name = '${dataServerName}'`,
      ).stdout;

      assert(
        serverNameCount === 0,
        `Data server name already exists; got [${dataServerName}]`,
      );
      assert(
        OS_LIST_MAP[dataOS] !== undefined,
        `Data OS not recognized; got [${dataOS}].`,
      );
      assert(
        patternInteger.test(dataCPUCores),
        `Data CPU cores can only contain digits; got [${dataCPUCores}].`,
      );
      assert(
        patternInteger.test(dataRAM),
        `Data RAM can only contain digits; got [${dataRAM}].`,
      );
      assert(
        patterUUID.test(dataStorageGroupUUID),
        `Data storage group UUID must be a valid UUID; got [${dataStorageGroupUUID}].`,
      );
      assert(
        patternInteger.test(dataStorageSize),
        `Data storage size can only contain digits; got [${dataStorageSize}].`,
      );
      assert(
        patterUUID.test(dataInstallISO),
        `Data install ISO must be a valid UUID; got [${dataInstallISO}].`,
      );
      assert(
        dataDriverISO === 'none' || patterUUID.test(dataDriverISO),
        `Data driver ISO must be a valid UUID when provided; got [${dataDriverISO}].`,
      );
      assert(
        patterUUID.test(dataAnvilUUID),
        `Data anvil UUID must be a valid UUID; got [${dataAnvilUUID}].`,
      );
    } catch (assertError) {
      console.log(
        `Failed to assert value when trying to provision a server; CAUSE: ${assertError}.`,
      );

      response.status(500).send();

      return;
    }

    const provisionServerJobData = `server_name=${dataServerName}
os=${dataOS}
cpu_cores=${dataCPUCores}
ram=${dataRAM}
storage_group_uuid=${dataStorageGroupUUID}
storage_size=${dataStorageSize}
install_iso=${dataInstallISO}
driver_iso=${dataDriverISO}`;

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
            AND anv.anvil_uuid = '${dataAnvilUUID}'
          ORDER BY sca_clu_nod.scan_cluster_node_name
          LIMIT 1
        ) AS pri_hos
        RIGHT JOIN (
          SELECT
            1 AS phr,
            anv.anvil_node1_host_uuid AS node1_host_uuid
          FROM anvils AS anv
          WHERE anv.anvil_uuid = '${dataAnvilUUID}'
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
