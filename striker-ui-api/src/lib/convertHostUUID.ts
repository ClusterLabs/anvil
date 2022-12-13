import { LOCAL } from './consts/LOCAL';

import { getLocalHostUUID } from './accessModule';

export const toHostUUID = (
  hostUUID: string,
  localHostUUID: string = getLocalHostUUID(),
) => (hostUUID === LOCAL ? localHostUUID : hostUUID);

export const toLocal = (
  hostUUID: string,
  localHostUUID: string = getLocalHostUUID(),
) => (hostUUID === localHostUUID ? LOCAL : hostUUID);
