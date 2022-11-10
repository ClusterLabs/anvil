import { RequestHandler } from 'express';

import { HOST_KEY_CHANGED_PREFIX } from '../../consts/HOST_KEY_CHANGED_PREFIX';

import { dbQuery, getLocalHostUUID, sub } from '../../accessModule';
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

  let hostName: string,
    hostOS: string,
    hostUUID: string,
    rawIsInetConnected: string,
    rawIsOSRegistered: string;

  const localHostUUID = getLocalHostUUID();

  try {
    ({
      host_name: hostName,
      host_os: hostOS,
      host_uuid: hostUUID,
      internet: rawIsInetConnected,
      os_registered: rawIsOSRegistered,
    } = sub('get_peer_data', {
      subModuleName: 'Striker',
      subParams: { password, port, target },
    }).stdout as {
      host_name: string;
      host_os: string;
      host_uuid: string;
      internet: string;
      os_registered: string;
    });
  } catch (subError) {
    stderr(`Failed to get peer data; CAUSE: ${subError}`);

    response.status(500).send();

    return;
  }

  const isConnected: boolean = hostName.length > 0;

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
    isInetConnected: rawIsInetConnected === '1',
    isOSRegistered: rawIsOSRegistered === 'yes',
  });
};
