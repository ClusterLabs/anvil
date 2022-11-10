import { RequestHandler } from 'express';

import { sub } from '../../accessModule';
import { stderr } from '../../shell';

export const getHostSSH: RequestHandler<
  unknown,
  {
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

  response.status(200).send({
    hostName,
    hostOS,
    hostUUID,
    isConnected: hostName.length > 0,
    isInetConnected: rawIsInetConnected === '1',
    isOSRegistered: rawIsOSRegistered === 'yes',
  });
};
