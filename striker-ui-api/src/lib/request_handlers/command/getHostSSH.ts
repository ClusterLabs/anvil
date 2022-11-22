import { RequestHandler } from 'express';

import { HOST_KEY_CHANGED_PREFIX } from '../../consts/HOST_KEY_CHANGED_PREFIX';

import { dbQuery, getLocalHostUUID, getPeerData } from '../../accessModule';
import { sanitizeSQLParam } from '../../sanitizeSQLParam';
import { stderr } from '../../shell';

export const getHostSSH: RequestHandler<
  unknown,
  {
    badSSHKeys?: DeleteSSHKeyConflictRequestBody;
    hostName: string;
    hostOS: string;
    hostUUID: string;
    isConnected: boolean;
    isInetConnected: boolean;
    isOSRegistered: boolean;
  },
  {
    password: string;
    port?: number;
    ipAddress: string;
  }
> = (request, response) => {
  const {
    body: { password, port = 22, ipAddress: target },
  } = request;

  let hostName: string;
  let hostOS: string;
  let hostUUID: string;
  let isConnected: boolean;
  let isInetConnected: boolean;
  let isOSRegistered: boolean;

  const localHostUUID = getLocalHostUUID();

  try {
    ({
      hostName,
      hostOS,
      hostUUID,
      isConnected,
      isInetConnected,
      isOSRegistered,
    } = getPeerData(target, { password, port }));
  } catch (subError) {
    stderr(`Failed to get peer data; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  let badSSHKeys: DeleteSSHKeyConflictRequestBody | undefined;

  if (!isConnected) {
    const rows = dbQuery(`
      SELECT sta.state_note, sta.state_uuid
      FROM states AS sta
      WHERE sta.state_host_uuid = '${localHostUUID}'
        AND sta.state_name = '${HOST_KEY_CHANGED_PREFIX}${sanitizeSQLParam(
      target,
    )}';`).stdout as [stateNote: string, stateUUID: string][];

    if (rows.length > 0) {
      badSSHKeys = rows.reduce<DeleteSSHKeyConflictRequestBody>(
        (previous, [, stateUUID]) => {
          previous[localHostUUID].push(stateUUID);

          return previous;
        },
        { [localHostUUID]: [] },
      );
    }
  }

  response.status(200).send({
    badSSHKeys,
    hostName,
    hostOS,
    hostUUID,
    isConnected,
    isInetConnected,
    isOSRegistered,
  });
};
