import { RequestHandler } from 'express';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import {
  getAnvilData,
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
      user = 'admin',
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
    localIPAddress = sub('find_matching_ip', {
      subModuleName: 'System',
      subParams: { host: peerIPAddress },
    }).stdout;
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
    sub('write_file', {
      subModuleName: 'Storage',
      subParams: {
        body: pgpassFileBody,
        file: pgpassFilePath,
        mode: '0600',
        overwrite: 1,
        secure: 1,
      },
    });
  } catch (subError) {
    stderr(`Failed to write ${pgpassFilePath}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  try {
    const [rawIsPeerDBReachable] = sub('call', {
      subModuleName: 'System',
      subParams: {
        shell_call: `PGPASSFILE="${pgpassFilePath}" ${SERVER_PATHS.usr.bin.psql.self} --host ${peerIPAddress} --port ${commonDBPort} --dbname ${commonDBName} --username ${commonDBUser} --no-password --tuples-only --no-align --command "SELECT 1"`,
      },
    }).stdout as [output: string, returnCode: number];

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
      database: {
        [localHostUUID]: { port: rawLocalDBPort },
      },
    } = getAnvilData<{ database: AnvilDataDatabaseHash }>({ database: true });

    localDBPort = sanitize(rawLocalDBPort, 'number');
  } catch (subError) {
    stderr(`Failed to get local database data from hash; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  const jobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${peerHostUUID} --host ${peerIPAddress} --port ${commonDBPort} --ping ${commonPing}`;
  const peerJobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${localHostUUID} --host ${localIPAddress} --port ${localDBPort} --ping ${commonPing}`;

  try {
    job({
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
