type APICommandInquireHostResponseBody = {
  badSshKeys?: {
    badKeys: string[];
  };
  hostName: string;
  hostOS: string;
  hostUUID: string;
  isConnected: boolean;
  isInetConnected: boolean;
  isOSRegistered: boolean;
};
