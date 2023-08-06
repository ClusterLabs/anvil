import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import {
  getData,
  getLocalHostUUID,
  getPeerData,
  job,
  sub,
} from '../../accessModule';
import { sanitize } from '../../sanitize';
import { rm, stderr, stdoutVar } from '../../shell';

export const createHostConnection: RequestHandler<
  unknown,
  undefined,
  CreateHostConnectionRequestBody
> = async (request, response) => {
  const {
    body: {
      dbName = 'anvil',
      ipAddress,
      isPing = false,
      password,
      port = 5432,
      sshPort = 22,
      user = 'root',
    },
  } = request;

  const commonDBName = sanitize(dbName, 'string');
  const commonIsPing = sanitize(isPing, 'boolean');
  const commonPassword = sanitize(password, 'string');
  const commonDBPort = sanitize(port, 'number');
  const commonDBUser = sanitize(user, 'string');
  const peerIPAddress = sanitize(ipAddress, 'string');
  const peerSSHPort = sanitize(sshPort, 'number');

  const commonPing = commonIsPing ? 1 : 0;

  let localDBPort: number;
  let localIPAddress: string;
  let isPeerReachable = false;
  let isPeerDBReachable = false;
  let peerHostUUID: string;

  try {
    ({ hostUUID: peerHostUUID, isConnected: isPeerReachable } =
      await getPeerData(peerIPAddress, {
        password: commonPassword,
        port: peerSSHPort,
      }));
  } catch (subError) {
    stderr(`Failed to get peer data; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  stdoutVar({ peerHostUUID, isPeerReachable });

  if (!isPeerReachable) {
    stderr(
      `Cannot connect to peer; please verify credentials and SSH keys validity.`,
    );

    return response.status(400).send();
  }

  try {
    [localIPAddress] = await sub('find_matching_ip', {
      params: [{ host: peerIPAddress }],
      pre: ['System'],
    });
  } catch (subError) {
    stderr(`Failed to get matching IP address; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  stdoutVar({ localIPAddress });

  const pgpassFilePath = '/tmp/.pgpass';
  const pgpassFileBody = `${peerIPAddress}:${commonDBPort}:${commonDBName}:${commonDBUser}:${commonPassword.replace(
    /:/g,
    '\\:',
  )}`;

  stdoutVar({ pgpassFilePath, pgpassFileBody });

  try {
    await sub('write_file', {
      params: [
        {
          body: pgpassFileBody,
          file: pgpassFilePath,
          mode: '0600',
          overwrite: 1,
          secure: 1,
        },
      ],
      pre: ['Storage'],
    });
  } catch (subError) {
    stderr(`Failed to write ${pgpassFilePath}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  try {
    const [rawIsPeerDBReachable]: [output: string, returnCode: number] =
      await sub('call', {
        params: [
          {
            shell_call: `PGPASSFILE="${pgpassFilePath}" ${SERVER_PATHS.usr.bin.psql.self} --host ${peerIPAddress} --port ${commonDBPort} --dbname ${commonDBName} --username ${commonDBUser} --no-password --tuples-only --no-align --command "SELECT 1"`,
          },
        ],
        pre: ['System'],
      });

    isPeerDBReachable = rawIsPeerDBReachable === '1';
  } catch (subError) {
    stderr(`Failed to test connection to peer database; CAUSE: ${subError}`);
  }

  try {
    rm(pgpassFilePath);
  } catch (fsError) {
    stderr(`Failed to remove ${pgpassFilePath}; CAUSE: ${fsError}`);

    return response.status(500).send();
  }

  stdoutVar({ isPeerDBReachable });

  if (!isPeerDBReachable) {
    stderr(
      `Cannot connect to peer database; please verify database credentials.`,
    );

    return response.status(400).send();
  }

  const localHostUUID = getLocalHostUUID();

  try {
    const {
      [localHostUUID]: { port: rawLocalDBPort },
    } = await getData<AnvilDataDatabaseHash>('database');

    localDBPort = sanitize(rawLocalDBPort, 'number');
  } catch (subError) {
    stderr(`Failed to get local database data from hash; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  const jobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${peerHostUUID} --host ${peerIPAddress} --port ${commonDBPort} --ping ${commonPing}`;
  const peerJobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${localHostUUID} --host ${localIPAddress} --port ${localDBPort} --ping ${commonPing}`;

  try {
    await job({
      file: __filename,
      job_command: jobCommand,
      job_data: `password=${commonPassword}
peer_job_command=${peerJobCommand}`,
      job_description: 'job_0012',
      job_name: 'striker-peer::add',
      job_title: 'job_0011',
    });
  } catch (subError) {
    stderr(`Failed to add peer ${peerHostUUID}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(201).send();
};
