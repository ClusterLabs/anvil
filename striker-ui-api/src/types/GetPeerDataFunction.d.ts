type PeerDataHash = {
  host_name: string;
  host_os: string;
  host_uuid: string;
  internet: string;
  os_registered: string;
};

type GetPeerDataOptions = Omit<
  ExecModuleSubroutineOptions,
  'subModuleName' | 'subParams'
> &
  ModuleSubroutineCommonParams & {
    password?: string;
    port?: number;
  };

type GetPeerDataFunction = (
  target: string,
  options?: GetPeerDataOptions,
) => {
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
};
