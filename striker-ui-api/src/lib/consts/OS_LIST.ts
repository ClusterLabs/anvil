import { execSync } from 'child_process';

import SERVER_PATHS from './SERVER_PATHS';

type OSKeyMapToName = Record<string, string>;

const osList: string[] = execSync(
  `${SERVER_PATHS.usr.sbin['striker-parse-os-list'].self} | ${SERVER_PATHS.usr.bin['sed'].self} -E 's/^.*name="os_list_([^"]+).*CDATA[[]([^]]+).*$/\\1,\\2/'`,
  {
    encoding: 'utf-8',
    timeout: 10000,
  },
).split('\n');

osList.pop();

const osKeyMapToName: OSKeyMapToName = osList.reduce((map, csv) => {
  const [osKey, osName] = csv.split(',', 2);

  map[osKey] = osName;

  return map;
}, {} as OSKeyMapToName);

export const OS_LIST: Readonly<string[]> = osList;
export const OS_LIST_MAP: Readonly<OSKeyMapToName> = osKeyMapToName;
