import { execSync } from 'child_process';

import SERVER_PATHS from './SERVER_PATHS';

type OSKeyMapToName = Record<string, string>;

/**
 * Note: `osinfo-query` has a `-f` option for selecting the desired fields to
 *       display, but not sure if it's supported in RHEL < 9. We can use the
 *       option after we've fully migrated to 9+.
 */
const osList: string[] = execSync(
  `${SERVER_PATHS.usr.bin['osinfo-query'].self} os`,
  {
    encoding: 'utf-8',
    timeout: 10000,
  },
)
  .trim()
  .split('\n')
  .slice(2);

const osKeyMapToName = osList.reduce<OSKeyMapToName>((map, csv) => {
  const [osKey, osName] = csv.split('|', 2);

  map[osKey.trim()] = osName.trim();

  return map;
}, {});

export const OS_LIST: Readonly<string[]> = osList;
export const OS_LIST_MAP: Readonly<OSKeyMapToName> = osKeyMapToName;
