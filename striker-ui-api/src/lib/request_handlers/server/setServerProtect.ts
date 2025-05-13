import { buildServerUpdateHandler } from './buildServerUpdateHandler';
import { serverSetProtectRequestBodySchema } from './schemas';

export const setServerProtect =
  buildServerUpdateHandler<ServerSetProtectRequestBody>(
    async ({ body }) => {
      await serverSetProtectRequestBodySchema.validate(body);
    },
    async ({ body }, server, sbin) => {
      const { drUuid, protect, protocol } = body;

      const command = sbin['anvil-manage-dr'].self;

      const commandArgs = ['--server', server.uuid, '--dr-host', drUuid];

      let operation: string;

      if (protect) {
        operation = 'protect';
      } else {
        operation = 'remove';
      }

      commandArgs.push(`--${operation}`);

      if (protocol) {
        commandArgs.push('--protocol', protocol);
      }

      return {
        file: __filename,
        job_command: [command, ...commandArgs].join(' '),
        job_host_uuid: drUuid,
        job_description: 'job_0384',
        job_name: `dr::${operation}`,
        job_title: 'job_0385',
      };
    },
  );
