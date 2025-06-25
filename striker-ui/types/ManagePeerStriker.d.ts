type InboundConnection = {
  dbPort: number;
  dbUser: string;
  ifaceId: string;
  ipAddress: string;
  networkLinkNumber: number;
  networkNumber: number;
  networkType: string;
};

type InboundConnectionList = Record<string, InboundConnection>;

type PeerConnection = {
  dbPort: number;
  dbUser: string;
  hostUUID: string;
  ipAddress: string;
  isDelete?: boolean;
  isEdit?: boolean;
  isNew?: boolean;
  isPingTest?: boolean;
};

type PeerConnectionList = Record<string, PeerConnection>;
