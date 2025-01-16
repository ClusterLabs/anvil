import { readFileSync } from 'fs';

import { SERVER_PATHS } from '../consts';

import { poutvar } from '../shell';

const getLocalHostUuid = () => {
  let localHostUuid: string;

  try {
    localHostUuid = readFileSync(SERVER_PATHS.etc.anvil['host.uuid'].self, {
      encoding: 'utf-8',
    }).trim();
  } catch (error) {
    throw new Error(`Failed to get local host UUID; CAUSE: ${error}`);
  }

  poutvar({ localHostUuid });

  return localHostUuid;
};

export { getLocalHostUuid as getLocalHostUUID };
