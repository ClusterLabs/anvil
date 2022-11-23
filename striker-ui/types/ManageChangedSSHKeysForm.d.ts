type ChangedSSHKeys = {
  [stateUUID: string]: {
    hostName: string;
    hostUUID: string;
    ipAddress: string;
    isChecked?: boolean;
  };
};

type ManageChangedSSHKeysFormOptionalProps = {
  mitmExternalHref?: LinkProps['href'];
  refreshInterval?: number;
};

type ManageChangedSSHKeysFormProps = ManageChangedSSHKeysFormOptionalProps;
