import { sub } from './sub';

export const getPeerData: GetPeerDataFunction = async (
  target,
  { password, port } = {},
) => {
  const [
    rawIsConnected,
    {
      host_name: hostName,
      host_os: hostOS,
      host_uuid: hostUUID,
      internet: rawIsInetConnected,
      os_registered: rawIsOSRegistered,
    },
  ]: [connected: string, data: PeerDataHash] = await sub('get_peer_data', {
    params: [{ password, port, target }],
    pre: ['Striker'],
  });

  return {
    hostName,
    hostOS,
    hostUUID,
    isConnected: rawIsConnected === '1',
    isInetConnected: rawIsInetConnected === '1',
    isOSRegistered: rawIsOSRegistered === 'yes',
  };
};
