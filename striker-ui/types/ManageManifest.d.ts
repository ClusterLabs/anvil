type ManifestAnId = {
  domain: string;
  prefix: string;
  sequence: number;
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

type ManifestNetworkConfig = {
  dnsCsv: string;
  /** Max Transmission Unit (MTU); unit: bytes */
  mtu: number;
  networks: ManifestNetworkList;
  ntpCsv: string;
};

type ManifestHostFenceList = {
  [fenceId: string]: {
    fenceName: string;
    fencePort: string;
  };
};

type ManifestHostNetworkList = {
  [networkId: string]: {
    networkIp: string;
    networkNumber: number;
    networkType: string;
  };
};

type ManifestHostUpsList = {
  [upsId: string]: {
    isUsed: boolean;
    upsName: string;
  };
};

type ManifestHost = {
  fences?: ManifestHostFenceList;
  hostName: string;
  hostNumber: number;
  hostType: string;
  networks?: ManifestHostNetworkList;
  upses?: ManifestHostUpsList;
};

type ManifestHostList = {
  [hostId: string]: ManifestHost;
};

type ManifestHostConfig = {
  hosts: ManifestHostList;
};

type AnIdInputGroupOptionalProps = {
  previous?: Partial<ManifestAnId>;
};

type AnIdInputGroupProps<M extends MapToInputTestID> =
  AnIdInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };

type AnNetworkEventHandlerPreviousArgs = {
  networkId: string;
} & Pick<ManifestNetwork, 'networkType'>;

type AnNetworkCloseEventHandler = (
  args: AnNetworkEventHandlerPreviousArgs,
  ...handlerArgs: Parameters<IconButtonMouseEventHandler>
) => ReturnType<IconButtonMouseEventHandler>;

type AnNetworkTypeChangeEventHandler = (
  args: AnNetworkEventHandlerPreviousArgs,
  ...handlerArgs: Parameters<SelectChangeEventHandler>
) => ReturnType<SelectChangeEventHandler>;

type AnNetworkInputGroupOptionalProps = {
  inputGatewayId?: string;
  inputGatewayLabel?: string;
  inputMinIpLabel?: string;
  inputSubnetMaskLabel?: string;
  onClose?: AnNetworkCloseEventHandler;
  onNetworkTypeChange?: AnNetworkTypeChangeEventHandler;
  previous?: {
    gateway?: string;
    minIp?: string;
    subnetMask?: string;
  };
  readonlyNetworkName?: boolean;
  showCloseButton?: boolean;
  showGateway?: boolean;
};

type AnNetworkInputGroupProps<M extends MapToInputTestID> =
  AnNetworkInputGroupOptionalProps & {
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

type AnHostInputGroupOptionalProps = {
  previous?: Pick<ManifestHost, 'fences' | 'networks' | 'upses'>;
};

type AnHostInputGroupProps<M extends MapToInputTestID> =
  AnHostInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    hostLabel: string;
  };

type AnNetworkConfigInputGroupOptionalProps = {
  previous?: Partial<ManifestNetworkConfig>;
};

type AnNetworkConfigInputGroupProps<M extends MapToInputTestID> =
  AnNetworkConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    networkListEntries: Array<[string, ManifestNetwork]>;
    setNetworkList: import('react').Dispatch<
      import('react').SetStateAction<ManifestNetworkList>
    >;
  };

type AnHostConfigInputGroupOptionalProps = {
  knownFences?: APIManifestTemplateFenceList;
  knownUpses?: APIManifestTemplateUpsList;
  previous?: Partial<ManifestHostConfig>;
};

type AnHostConfigInputGroupProps<M extends MapToInputTestID> =
  AnHostConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    networkListEntries: Array<[string, ManifestNetwork]>;
  };

type AddManifestInputGroupOptionalProps = Pick<
  AnHostConfigInputGroupOptionalProps,
  'knownFences' | 'knownUpses'
> & {
  previous?: Partial<ManifestAnId> & {
    hostConfig?: Partial<ManifestHostConfig>;
    networkConfig?: Partial<ManifestNetworkConfig>;
  };
};

type AddManifestInputGroupProps<M extends MapToInputTestID> =
  AddManifestInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };

type EditManifestInputGroupProps<M extends MapToInputTestID> =
  AddManifestInputGroupProps<M>;

type RunManifestInputGroupOptionalProps = {
  knownHosts?: APIHostOverviewList;
};

type RunManifestInputGroupProps<M extends MapToInputTestID> =
  RunManifestInputGroupOptionalProps & AddManifestInputGroupProps<M>;
