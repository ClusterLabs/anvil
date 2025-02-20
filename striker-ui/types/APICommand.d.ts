type APICommandInquireHostRequestBody = {
  password: string;
  target: string;
};

type APICommandInquireHostResponseBody = {
  badSshKeys?: APIDeleteSSHKeyConflictRequestBody;
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
};
