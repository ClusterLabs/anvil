import { LOCAL } from './consts/LOCAL';

import { getLocalHostUUID } from './accessModule';

export const toHostUUID = (hostUUID: string) =>
  hostUUID === LOCAL ? getLocalHostUUID() : hostUUID;

export const toLocal = (
  hostUUID: string,
  localHostUUID: string = getLocalHostUUID(),
) => (hostUUID === localHostUUID ? LOCAL : hostUUID);
