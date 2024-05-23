type APICommandInquireHostResponseBody = {
  badSshKeys?: Record<string, string[]>;
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
};
