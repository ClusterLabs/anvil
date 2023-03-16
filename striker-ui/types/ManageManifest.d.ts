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

type AnvilNetworkConfigNetwork = {
  networkGateway?: string;
  networkMinIp: string;
  networkNumber: number;
  networkSubnetMask: string;
  networkType: string;
};

type AnvilNetworkConfigNetworkList = {
  [networkId: string]: AnvilNetworkConfigNetwork;
};

type AnvilNetworkCloseHandler = (
  args: { networkId: string } & Pick<AnvilNetworkConfigNetwork, 'networkType'>,
  ...handlerArgs: Parameters<IconButtonMouseEventHandler>
) => ReturnType<IconButtonMouseEventHandler>;

type AnvilNetworkInputGroupOptionalProps = {
  inputGatewayId?: string;
  inputGatewayLabel?: string;
  inputMinIpLabel?: string;
  inputSubnetMaskLabel?: string;
  onClose?: AnvilNetworkCloseHandler;
  previous?: {
    gateway?: string;
    minIp?: string;
    subnetMask?: string;
  };
  showCloseButton?: boolean;
  showGateway?: boolean;
};

type AnvilNetworkInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    idPrefix: string;
    inputMinIpId: string;
    inputSubnetMaskId: string;
    networkId: string;
    networkNumber: number;
    networkType: string;
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

type AnvilNetworkConfigInputGroupOptionalProps = {
  previous?: {
    dnsCsv?: string;
    /** Max Transmission Unit (MTU); unit: bytes */
    mtu?: number;
    networks?: AnvilNetworkConfigNetworkList;
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
