import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr } from '../../shell';

type DistinctJobParams = Omit<
  JobParams,
  'file' | 'line' | 'job_data' | 'job_progress'
>;

const MANAGE_HOST_POWER_JOB_PARAMS: {
  poweroff: DistinctJobParams;
  reboot: DistinctJobParams;
} = {
  poweroff: {
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --poweroff -y`,
    job_name: 'poweroff::system',
    job_title: 'job_0010',
    job_description: 'job_0008',
  },
  reboot: {
    job_command: `${SERVER_PATHS.usr.sbin['anvil-manage-power'].self} --reboot -y`,
    job_name: 'reboot::system',
    job_title: 'job_0009',
    job_description: 'job_0006',
  },
};

export const buildHostPowerHandler: (
  task?: 'poweroff' | 'reboot',
) => RequestHandler =
  (task = 'reboot') =>
  async (request, response) => {
    const subParams: JobParams = {
      file: __filename,

      ...MANAGE_HOST_POWER_JOB_PARAMS[task],
    };

    try {
      await job(subParams);
    } catch (subError) {
      stderr(`Failed to ${task} host; CAUSE: ${subError}`);

      return response.status(500).send();
    }

    response.status(204).send();
  };
