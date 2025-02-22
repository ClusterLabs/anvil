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

  return badHostUuid;
};
