import assert from 'assert';
import { SpawnSyncReturns, spawnSync } from 'child_process';

import { P_UUID, SERVER_PATHS } from './consts';

import { poutvar } from './shell';

const MAP_TO_FLAG_BUNDLE: {
  'alert-overrides': Record<keyof AlertOverrideRequestBody | 'uuid', string>;
  'mail-servers': Record<keyof MailServerRequestBody | 'uuid', string>;
  recipients: Record<keyof MailRecipientRequestBody | 'uuid', string>;
} = {
  'alert-overrides': {
    hostUuid: '--alert-override-host-uuid',
    level: '--alert-override-alert-level',
    mailRecipientUuid: '--alert-override-recipient-uuid',
    uuid: '--alert-override-uuid',
  },
  'mail-servers': {
    address: '--mail-server-address',
    authentication: '--mail-server-authentication',
    heloDomain: '--mail-server-helo-domain',
    password: '--mail-server-password',
    port: '--mail-server-port',
    security: '--mail-server-security',
    username: '--mail-server-username',
    uuid: '--mail-server-uuid',
  },
  recipients: {
    email: '--recipient-email',
    language: '--recipient-language',
    level: '--recipient-level',
    name: '--recipient-name',
    uuid: '--recipient-uuid',
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
): { uuid?: string } => {
  const shallow = { ...body };

  if (uuid) {
    shallow.uuid = uuid;
  }

  const commandArgs: string[] = Object.entries(
    MAP_TO_FLAG_BUNDLE[entities],
  ).reduce(
    (previous, [key, flag]) => {
      const value = shallow[key];

      if (value !== undefined) {
        previous.push(flag, String(value));
      }

      return previous;
    },
    [`--${entities}`, `--${operation}`, '--yes'],
  );

  poutvar({ commandArgs }, 'Manage alerts with args: ');

  let result: SpawnSyncReturns<string>;

  try {
    result = spawnSync(
      SERVER_PATHS.usr.sbin['anvil-manage-alerts'].self,
      commandArgs,
      { encoding: 'utf-8', timeout: 30000 },
    );

    const { error, signal, status, stderr, stdout } = result;

    poutvar(
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

  return {
    uuid: result.stdout.match(new RegExp(P_UUID))?.[0],
  };
};
