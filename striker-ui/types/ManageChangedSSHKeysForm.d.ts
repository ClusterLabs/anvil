type ChangedSSHKeys = {
  [stateUUID: string]: {
    hostName: string;
    hostUUID: string;
    ipAddress: string;
  };
};

type ManageChangedSSHKeysFormOptionalProps = {
  mitmExternalHref?: LinkProps['href'];
  refreshInterval?: number;
};

type ManageChangedSSHKeysFormProps = ManageChangedSSHKeysFormOptionalProps;
