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

type ManifestNetwork = {
  networkGateway?: string;
  networkMinIp: string;
  networkNumber: number;
  networkSubnetMask: string;
  networkType: string;
};

type ManifestNetworkList = {
  [networkId: string]: ManifestNetwork;
};

type AnvilNetworkEventHandlerPreviousArgs = {
  networkId: string;
} & Pick<ManifestNetwork, 'networkType'>;

type AnvilNetworkCloseEventHandler = (
  args: AnvilNetworkEventHandlerPreviousArgs,
  ...handlerArgs: Parameters<IconButtonMouseEventHandler>
) => ReturnType<IconButtonMouseEventHandler>;

type AnvilNetworkTypeChangeEventHandler = (
  args: AnvilNetworkEventHandlerPreviousArgs,
  ...handlerArgs: Parameters<SelectChangeEventHandler>
) => ReturnType<SelectChangeEventHandler>;

type AnvilNetworkInputGroupOptionalProps = {
  inputGatewayId?: string;
  inputGatewayLabel?: string;
  inputMinIpLabel?: string;
  inputSubnetMaskLabel?: string;
  onClose?: AnvilNetworkCloseEventHandler;
  onNetworkTypeChange?: AnvilNetworkTypeChangeEventHandler;
  previous?: {
    gateway?: string;
    minIp?: string;
    subnetMask?: string;
  };
  readonlyNetworkName?: boolean;
  showCloseButton?: boolean;
  showGateway?: boolean;
};

type AnvilNetworkInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    idPrefix: string;
    inputMinIpId: string;
    inputNetworkTypeId: string;
    inputSubnetMaskId: string;
    networkId: string;
    networkNumber: number;
    networkType: string;
    networkTypeOptions: SelectItem[];
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
    networks?: ManifestNetworkList;
    ntpCsv?: string;
  };
};

type AnvilNetworkConfigInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    networkList: ManifestNetworkList;
    setNetworkList: import('react').Dispatch<
      import('react').SetStateAction<ManifestNetworkList>
    >;
  };

type AddManifestInputGroupOptionalProps = {
  previous?: {
    networkConfig?: AnvilNetworkConfigInputGroupOptionalProps['previous'];
  };
};

type AddManifestInputGroupProps<M extends MapToInputTestID> =
  AddManifestInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };
