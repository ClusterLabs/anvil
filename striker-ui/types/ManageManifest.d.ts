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

type AnvilIdInputGroupOptionalProps = {
  previous?: Partial<ManifestAnId>;
};

type AnvilIdInputGroupProps<M extends MapToInputTestID> =
  AnvilIdInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
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
  previous?: Pick<ManifestHost, 'fences' | 'networks' | 'upses'>;
};

type AnvilHostInputGroupProps<M extends MapToInputTestID> =
  AnvilHostInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    hostLabel: string;
  };

type AnvilNetworkConfigInputGroupOptionalProps = {
  previous?: Partial<ManifestNetworkConfig>;
};

type AnvilNetworkConfigInputGroupProps<M extends MapToInputTestID> =
  AnvilNetworkConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    networkListEntries: Array<[string, ManifestNetwork]>;
    setNetworkList: import('react').Dispatch<
      import('react').SetStateAction<ManifestNetworkList>
    >;
  };

type AnvilHostConfigInputGroupOptionalProps = {
  knownFences?: APIManifestTemplateFenceList;
  knownUpses?: APIManifestTemplateUpsList;
  previous?: Partial<ManifestHostConfig>;
};

type AnvilHostConfigInputGroupProps<M extends MapToInputTestID> =
  AnvilHostConfigInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    networkListEntries: Array<[string, ManifestNetwork]>;
  };

type AddManifestInputGroupOptionalProps = Pick<
  AnvilHostConfigInputGroupOptionalProps,
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
