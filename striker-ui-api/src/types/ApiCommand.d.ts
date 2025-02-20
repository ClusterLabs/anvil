type GetHostSshRequestBody = {
  password: string;
  port?: number;
  target: string;
};

type GetHostSshResponseBody = {
  badSshKeys?: DeleteSshKeyConflictRequestBody;
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
};
