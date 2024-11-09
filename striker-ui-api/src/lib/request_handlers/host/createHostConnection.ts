import { RequestHandler } from 'express';
import { writeFileSync } from 'fs';

import SERVER_PATHS from '../../consts/SERVER_PATHS';

import {
  getData,
  getLocalHostUUID,
  getPeerData,
  job,
  sub,
} from '../../accessModule';
import { buildJobDataFromObject } from '../../buildJobData';
import { sanitize } from '../../sanitize';
import { rm, perr, poutvar, systemCall, uuid } from '../../shell';

export const createHostConnection: RequestHandler<
  unknown,
  undefined,
  CreateHostConnectionRequestBody
> = async (request, response) => {
  const {
    body: { dbName, ipAddress, isPing, password, port, sshPort, user },
  } = request;

  const commonDBName = sanitize(dbName, 'string', { fallback: 'anvil' });
  const commonIsPing = sanitize(isPing, 'boolean');
  const commonPassword = sanitize(password, 'string');
  const commonDBPort = sanitize(port, 'number', { fallback: 5432 });
  const commonDBUser = sanitize(user, 'string', { fallback: 'admin' });
  const peerIPAddress = sanitize(ipAddress, 'string');
  const peerSSHPort = sanitize(sshPort, 'number', { fallback: 22 });

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
    perr(`Failed to get peer data; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  poutvar({ peerHostUUID, isPeerReachable });

  if (!isPeerReachable) {
    perr(
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
    perr(`Failed to get matching IP address; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  poutvar({ localIPAddress });

  const pgpassFilePath = `/tmp/.pgpass-${uuid()}`;
  const pgpassFileBody = `${peerIPAddress}:${commonDBPort}:${commonDBName}:${commonDBUser}:${commonPassword.replace(
    /:/g,
    '\\:',
  )}`;

  poutvar({ pgpassFilePath, pgpassFileBody });

  try {
    writeFileSync(pgpassFilePath, pgpassFileBody, {
      encoding: 'utf-8',
      mode: 0o600,
    });
  } catch (subError) {
    perr(`Failed to write ${pgpassFilePath}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  try {
    const timestamp = String(Date.now());

    const echo = systemCall(
      SERVER_PATHS.usr.bin.psql.self,
      [
        '--no-align',
        '--no-password',
        '--tuples-only',
        '--command',
        `SELECT ${timestamp};`,
        '--dbname',
        commonDBName,
        '--host',
        peerIPAddress,
        '--port',
        String(commonDBPort),
        '--username',
        commonDBUser,
      ],
      { env: { PGPASSFILE: pgpassFilePath } },
    ).trim();

    poutvar(
      { timestamp, echo },
      'Ask the peer database to echo the current timestamp: ',
    );

    isPeerDBReachable = echo === timestamp;
  } catch (subError) {
    perr(`Failed to test connection to peer database; CAUSE: ${subError}`);
  }

  try {
    rm(pgpassFilePath);
  } catch (fsError) {
    perr(`Failed to remove ${pgpassFilePath}; CAUSE: ${fsError}`);

    return response.status(500).send();
  }

  poutvar({ isPeerDBReachable });

  if (!isPeerDBReachable) {
    perr(
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
    perr(`Failed to get local database data from hash; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  const jobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${peerHostUUID} --host ${peerIPAddress} --port ${commonDBPort} --ping ${commonPing}`;
  const peerJobCommand = `${SERVER_PATHS.usr.sbin['striker-manage-peers'].self} --add --host-uuid ${localHostUUID} --host ${localIPAddress} --port ${localDBPort} --ping ${commonPing}`;

  try {
    await job({
      file: __filename,
      job_command: jobCommand,
      job_data: buildJobDataFromObject({
        password: commonPassword,
        peer_job_command: peerJobCommand,
      }),
      job_description: 'job_0012',
      job_name: 'striker-peer::add',
      job_title: 'job_0011',
    });
  } catch (subError) {
    perr(`Failed to add peer ${peerHostUUID}; CAUSE: ${subError}`);

    return response.status(500).send();
  }

  response.status(201).send();
};
