import { RequestHandler } from 'express';

// import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { sub } from '../../accessModule';

export const createServer: RequestHandler = ({ body }, response) => {
  console.log('Creating server.');

  if (body) {
    const {
      serverName,
      cpuCores,
      memory,
      virtualDisks: [{ storageSize, storageGroupUUID }],
      installISOFileUUID,
      driverISOFileUUIDs,
      anvilUUID,
      optimizeForOS,
    } = body;

    const provisionServerJobData = `
server_name=${serverName}
os=${optimizeForOS}
cpu_cores=${cpuCores}
ram=${memory}
storage_group_uuid=${storageGroupUUID}
storage_size=${storageSize}
install_iso=${installISOFileUUID}
driver_iso=${driverISOFileUUIDs}`;

    console.log(`provisionServerJobData: ${provisionServerJobData}`);

    const { stdout: provisionServerJobHostUUID } = sub(
      'get_primary_host_uuid',
      {
        subModuleName: 'Cluster',
        subParams: { anvil_uuid: anvilUUID },
      },
    );

    console.log(`provisionServerJobHostUUID: [${provisionServerJobHostUUID}]`);

    // sub('insert_or_update_jobs', {
    //   subParams: {
    //     file: __filename,
    //     line: 0,
    //     job_command: SERVER_PATHS.usr.sbin['anvil-provision-server'].self,
    //     job_data: provisionServerJobData,
    //     job_name: 'server:provision',
    //     job_title: 'job_0147',
    //     job_description: 'job_0148',
    //     job_progress: 0,
    //     job_host_uuid: provisionServerJobHostUUID,
    //   },
    // });
  }

  response.status(202).send();
};
