import assert from 'assert';
import { spawnSync } from 'child_process';

import { SERVER_PATHS } from './consts';

import { stdoutVar } from './shell';

const MAP_TO_FLAG_BUNDLE = {
  'alert-overrides': {
    '--alert-override-alert-level': 'level',
    '--alert-override-host-uuid': 'hostUuid',
    '--alert-override-recipient-uuid': 'recipientUuid',
    '--alert-override-uuid': 'uuid',
  },
  'mail-servers': {
    '--mail-server-address': 'address',
    '--mail-server-authentication': 'authentication',
    '--mail-server-helo-domain': 'heloDomain',
    '--mail-server-password': 'password',
    '--mail-server-port': 'port',
    '--mail-server-security': 'security',
    '--mail-server-username': 'username',
    '--mail-server-uuid': 'uuid',
  },
  recipients: {
    '--recipient-email': 'email',
    '--recipient-language': 'language',
    '--recipient-level': 'level',
    '--recipient-name': 'name',
    '--recipient-uuid': 'uuid',
  },
};

export const execManageAlerts = (
  entities: 'alert-overrides' | 'mail-servers' | 'recipients',
  operation: 'add' | 'edit' | 'delete',
  {
    body,
    uuid,
  }: {
    body?: Record<string, unknown>;
    uuid?: string;
  } = {},
) => {
  const shallow = { ...body };

  if (uuid) {
    shallow.uuid = uuid;
  }

  const commandArgs: string[] = Object.entries(
    MAP_TO_FLAG_BUNDLE[entities],
  ).reduce(
    (previous, [flag, key]) => {
      const value = shallow[key];

      if (value) {
        previous.push(flag, String(value));
      }

      return previous;
    },
    [`--${entities}`, `--${operation}`, '--yes'],
  );

  stdoutVar({ commandArgs }, 'Manage alerts with args: ');

  try {
    const { error, signal, status, stderr, stdout } = spawnSync(
      SERVER_PATHS.usr.sbin['anvil-manage-alerts'].self,
      commandArgs,
      { encoding: 'utf-8', timeout: 10000 },
    );

    stdoutVar(
      { error, signal, status, stderr, stdout },
      'Manage alerts returned: ',
    );

    assert.strictEqual(
      status,
      0,
      `Expected status to be 0, but got [${status}]`,
    );

    assert.strictEqual(
      error,
      undefined,
      `Expected no error, but got [${error}]`,
    );
  } catch (error) {
    throw new Error(`Failed to complete manage alerts; CAUSE: ${error}`);
  }
};
