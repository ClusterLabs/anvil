type AnvilIdInputGroupOptionalProps = {
  previous?: {
    anvilIdPrefix?: string;
    anvilIdDomain?: string;
    anvilIdSequence?: number;
  };
};

type AnvilIdInputGroupProps<M extends MapToInputTestID> =
  AnvilIdInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };

type AnvilNetworkInputGroupOptionalProps = {
  inputGatewayId?: string;
  inputGatewayLabel?: string;
  inputMinIpLabel?: string;
  inputSubnetMaskLabel?: string;
  previous?: {
    gateway?: string;
    minIp?: string;
    subnetMask?: string;
  };
  showGateway?: boolean;
};

type AnvilNetworkInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    idPrefix: string;
    inputMinIpId: string;
    inputSubnetMaskId: string;
    networkName: string;
  };

type AnvilHostInputGroupOptionalProps = {
  previous?: {
    fences?: {
      [fenceId: string]: {
        fenceName: string;
        fencePort: number;
      };
    };
    networks?: {
      [networkId: string]: {
        networkIp: string;
        networkNumber: number;
        networkType: string;
      };
    };
    upses?: {
      [upsId: string]: {
        isPowerHost: boolean;
        upsName: string;
      };
    };
  };
};

type AnvilHostInputGroupProps<M extends MapToInputTestID> =
  AnvilHostInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    hostLabel: string;
    idPrefix: string;
  };

type AnvilNetworkConfigNetwork = {
  networkGateway?: string;
  networkMinIp: string;
  networkNumber: number;
  networkSubnetMask: string;
  networkType: string;
};

type AnvilNetworkConfigInputGroupOptionalProps = {
  previous?: {
    dnsCsv?: string;
    /** Max Transmission Unit (MTU); unit: bytes */
    mtu?: number;
    networks?: {
      [networkId: string]: AnvilNetworkConfigNetwork;
    };
    ntpCsv?: string;
  };
};

type AnvilNetworkConfigInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };

type AddAnvilInputGroupProps<M extends MapToInputTestID> = {
  formUtils: FormUtils<M>;
};
