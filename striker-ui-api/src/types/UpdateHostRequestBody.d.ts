type SetHostInstallTargetRequestBody = {
  isEnableInstallTarget: boolean;
};

type PrepareHostRequestBody = {
  enterpriseUUID?: string;
  hostIPAddress: string;
  hostName: string;
  hostPassword: string;
  hostSSHPort?: number;
  hostType: string;
  hostUser?: string;
  hostUUID?: string;
  redhatPassword: string;
  redhatUser: string;
};

type UpdateHostParams = {
  hostUUID: string;
};
