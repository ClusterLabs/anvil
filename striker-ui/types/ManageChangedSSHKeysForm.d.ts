type ChangedSSHKeys = {
  [hostUUID: string]: {
    hostName: string;
    hostUUID: string;
    ipAddress: string;
    isChecked?: boolean;
  };
};

type ManageChangedSSHKeysFormOptionalProps = {
  mitmExternalHref?: LinkProps['href'];
};

type ManageChangedSSHKeysFormProps = ManageChangedSSHKeysFormOptionalProps;
