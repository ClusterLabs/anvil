import assert from 'assert';

import { SERVER_PATHS } from '../consts';

import { perr } from '../shell';
import { sub } from './sub';

export const listNicModels = async (target: string) => {
  let list: string[] = [];

  try {
    const [stdout, , code] = await sub<[string, string, string]>('call', {
      as: 'root',
      params: [
        {
          target,
          shell_call: `${SERVER_PATHS.usr.libexec['qemu-kvm'].self} -nic model=help`,
        },
      ],
      pre: ['Remote'],
    });

    assert(Number(code) === 0, `Subroutine failed with code ${code}`);

    [, ...list] = stdout.split('\n');
  } catch (error) {
    perr(`Failed to list NIC model; CAUSE: ${error}`);
  }

  return list;
};
