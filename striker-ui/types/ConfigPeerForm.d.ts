type InboundConnectionList = {
  [ipAddress: string]: {
    dbPort: number;
    dbUser: string;
    ifaceId: string;
    ipAddress: string;
    networkLinkNumber: number;
    networkNumber: number;
    networkType: string;
  };
};

type PeerConnectionList = {
  [peer: string]: {
    dbPort: number;
    dbUser: string;
    hostUUID: string;
    ipAddress: string;
    isChecked?: boolean;
    isDelete?: boolean;
    isEdit?: boolean;
    isNew?: boolean;
    isPingTest?: boolean;
  };
};

type ConfigPeerFormOptionalProps = {
  refreshInterval?: number;
};

type ConfigPeerFormProps = ConfigPeerFormOptionalProps;
