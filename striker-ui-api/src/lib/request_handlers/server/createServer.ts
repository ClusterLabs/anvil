import assert from 'assert';
import { RequestHandler } from 'express';

import { DELETED, OS_LIST_MAP, REP_UUID, SERVER_PATHS } from '../../consts';

import { job, query } from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { sanitize } from '../../sanitize';
import { perr, pout, poutvar } from '../../shell';

export const createServer: RequestHandler = async (request, response) => {
  const { body = {} } = request;

  poutvar(body, 'Creating server; body=');

  const {
    serverName: rServerName,
    cpuCores: rCpuCores,
    memory: rMemory,
    virtualDisks: [
      {
        storageSize: rStorageSize = undefined,
        storageGroupUUID: rStorageGroupUuid = undefined,
      } = {},
    ] = [],
    installISOFileUUID: rInstallIsoUuid,
    driverISOFileUUID: rDriverIsoUuid,
    anvilUUID: rAnvilUuid,
    optimizeForOS: rOptimizeForOs,
  } = body;

  const serverName = sanitize(rServerName, 'string');
  const os = sanitize(rOptimizeForOs, 'string');
  const cpuCores = sanitize(rCpuCores, 'number');
  const memory = sanitize(rMemory, 'number');
  const storageGroupUuid = sanitize(rStorageGroupUuid, 'string');
  const storageSize = sanitize(rStorageSize, 'number');
  const installIsoUuid = sanitize(rInstallIsoUuid, 'string');
  const driverIsoUuid = sanitize(rDriverIsoUuid, 'string', {
    fallback: 'none',
  });
  const anvilUuid = sanitize(rAnvilUuid, 'string');

  try {
    assert(
      /^[0-9a-z_-]+$/i.test(serverName),
      `Data server name can only contain alphanumeric, underscore, and hyphen characters; got [${serverName}]`,
    );

    const [[serverNameCount]] = await query(
      `SELECT
          COUNT(server_uuid)
        FROM servers
        WHERE server_state != '${DELETED}'
          AND server_name = '${serverName}'`,
    );

    assert(
      serverNameCount === 0,
      `Data server name already exists; got [${serverName}]`,
    );

    assert(
      OS_LIST_MAP[os] !== undefined,
      `Data OS not recognized; got [${os}]`,
    );

    assert(
      Number.isInteger(cpuCores),
      `Data CPU cores can only contain digits; got [${cpuCores}]`,
    );

    assert(
      Number.isInteger(memory),
      `Data RAM can only contain digits; got [${memory}]`,
    );

    assert(
      REP_UUID.test(storageGroupUuid),
      `Data storage group UUID must be a valid UUID; got [${storageGroupUuid}]`,
    );

    assert(
      Number.isInteger(storageSize),
      `Data storage size can only contain digits; got [${storageSize}]`,
    );

    assert(
      REP_UUID.test(installIsoUuid),
      `Data install ISO must be a valid UUID; got [${installIsoUuid}]`,
    );

    assert(
      driverIsoUuid === 'none' || REP_UUID.test(driverIsoUuid),
      `Data driver ISO must be a valid UUID when provided; got [${driverIsoUuid}]`,
    );

    assert(
      REP_UUID.test(anvilUuid),
      `Data anvil UUID must be a valid UUID; got [${anvilUuid}]`,
    );
  } catch (assertError) {
    pout(
      `Failed to assert value when trying to provision a server; CAUSE: ${assertError}`,
    );

    return response.status(400).send();
  }

  const [[provisionServerJobHostUuid]]: [[string]] = await query(
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
            AND anv.anvil_uuid = '${anvilUuid}'
          ORDER BY sca_clu_nod.scan_cluster_node_name
          LIMIT 1
        ) AS pri_hos
        RIGHT JOIN (
          SELECT
            1 AS phr,
            anv.anvil_node1_host_uuid AS node1_host_uuid
          FROM anvils AS anv
          WHERE anv.anvil_uuid = '${anvilUuid}'
        ) AS nod_1
          ON pri_hos.phl = nod_1.phr;`,
  );

  pout(`provisionServerJobHostUuid=[${provisionServerJobHostUuid}]`);

  try {
    await job({
      file: __filename,
      job_command: SERVER_PATHS.usr.sbin['anvil-provision-server'].self,
      job_data: buildJobDataFromObject({
        obj: {
          cpu_cores: cpuCores,
          driver_iso: driverIsoUuid,
          install_iso: installIsoUuid,
          os,
          ram: memory,
          server_name: serverName,
          storage_group_uuid: storageGroupUuid,
          storage_size: storageSize,
        },
      }),
      job_name: 'server:provision',
      job_title: 'job_0147',
      job_description: 'job_0148',
      job_host_uuid: provisionServerJobHostUuid,
    });
  } catch (subError) {
    perr(`Failed to provision server; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(202).send();
};
