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

    let provisionServerJobHostUUID: string;

    ({ stdout: provisionServerJobHostUUID } = sub('get_primary_host_uuid', {
      subModuleName: 'Cluster',
      subParams: {
        anvil_uuid: anvilUUID,
        test_access_user: 'admin',
      },
    }));

    console.log(
      `provisionServerJobHostUUID from Cluster->get_primary_host_uuid(): [${provisionServerJobHostUUID}]`,
    );

    if (provisionServerJobHostUUID === '') {
      [[provisionServerJobHostUUID]] = dbQuery(`
        SELECT anvil_node1_host_uuid
        FROM anvils
        WHERE anvil_uuid = '${anvilUUID}'`).stdout;
    }

    console.log(
      `provisionServerJobHostUUID from DB: [${provisionServerJobHostUUID}]`,
    );

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
