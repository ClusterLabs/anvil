import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import { job } from '../../accessModule';
import { stderr } from '../../shell';

type DistinctDBJobParams = Omit<
  DBJobParams,
  'file' | 'line' | 'job_data' | 'job_progress'
>;

const MANAGE_HOST_POWER_JOB_PARAMS: {
  poweroff: DistinctDBJobParams;
  reboot: DistinctDBJobParams;
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
  (request, response) => {
    const subParams: DBJobParams = {
      file: __filename,
      line: 0,
      job_data: '',
      job_progress: 100,

      ...MANAGE_HOST_POWER_JOB_PARAMS[task],
    };

    try {
      job({ subParams });
    } catch (subError) {
      stderr(`Failed to ${task} host; CAUSE: ${subError}`);

      response.status(500).send();

      return;
    }

    response.status(204).send();
  };
