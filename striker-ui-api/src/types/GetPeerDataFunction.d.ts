type PeerDataHash = {
  host_name: string;
  host_os: string;
  host_uuid: string;
  internet: string;
  os_registered: string;
};

type GetPeerDataOptions = SubroutineCommonParams & {
  password?: string;
  port?: number;
};

type GetPeerDataFunction = (
  target: string,
  options?: GetPeerDataOptions,
) => Promise<{
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
}>;
