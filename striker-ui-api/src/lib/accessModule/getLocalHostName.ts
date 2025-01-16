import { readFileSync } from 'fs';

import { SERVER_PATHS } from '../consts';

import { poutvar } from '../shell';

export const getLocalHostName = () => {
  let localHostName: string;

  try {
    localHostName = readFileSync(SERVER_PATHS.etc.hostname.self, {
      encoding: 'utf-8',
    }).trim();
  } catch (error) {
    throw new Error(`Failed to get local host name; CAUSE: ${error}`);
  }

  poutvar({ localHostName });

  return localHostName;
};
