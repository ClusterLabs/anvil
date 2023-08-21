import { execSync } from 'child_process';

import SERVER_PATHS from './SERVER_PATHS';

type OSKeyMapToName = Record<string, string>;

const osList: string[] = execSync(
  SERVER_PATHS.usr.sbin['striker-parse-os-list'].self,
  {
    encoding: 'utf-8',
    timeout: 10000,
  },
)
  .trim()
  .split('\n');

const osKeyMapToName: OSKeyMapToName = osList.reduce((map, csv) => {
  const [osKey, osName] = csv
    .replace(/^key=([^\s]+),name=['"](.*)['"]$/, '$1,$2')
    .split(',', 2);

  map[osKey] = osName;

  return map;
}, {} as OSKeyMapToName);

export const OS_LIST: Readonly<string[]> = osList;
export const OS_LIST_MAP: Readonly<OSKeyMapToName> = osKeyMapToName;
