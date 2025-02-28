import { sub } from './sub';

export const getHostFromTarget = async (
  target: string,
): Promise<string | undefined> => {
  let badHostUuid: string | undefined;

  [badHostUuid] = await sub<[string]>('host_from_ip_address', {
    params: [
      {
        ip_address: target,
      },
    ],
    pre: ['Get'],
  });

  if (badHostUuid) {
    return badHostUuid;
  }

  [badHostUuid] = await sub<[string]>('host_uuid_from_name', {
    params: [
      {
        host_name: target,
      },
    ],
    pre: ['Get'],
  });

  // Empty string will cause input validation to fail because it's treated as
  // input is provided but won't match the UUID pattern.
  if (!badHostUuid) {
    badHostUuid = undefined;
  }

  return badHostUuid;
};
