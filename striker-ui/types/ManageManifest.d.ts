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
  hostName?: string;
  hostNumber: number;
  hostType: string;
  ipmiIp?: string;
  networks?: ManifestHostNetworkList;
  upses?: ManifestHostUpsList;
};

type ManifestHostList = {
  [hostId: string]: ManifestHost;
};

type ManifestHostConfig = {
  hosts: ManifestHostList;
};

type ManifestFormInputHandler = (
  container: APIBuildManifestRequestBody,
  input: HTMLInputElement,
) => void;

type MapToManifestFormInputHandler = Record<string, ManifestFormInputHandler>;

/** ---------- Component types ---------- */

type AnIdInputGroupOptionalProps = {
  slotProps?: {
    grid?: import('@mui/material/Grid2').Grid2Props;
  };
};

type AnIdInputGroupProps = AnIdInputGroupOptionalProps;

type AnNetworkEventHandlerPreviousArgs = {
  networkId: string;
} & Pick<ManifestNetwork, 'networkType'>;

type AnNetworkChangeEventHandler<Handler> = (
  args: AnNetworkEventHandlerPreviousArgs,
  ...handlerArgs: Parameters<Handler>
) => ReturnType<Handler>;

type AnNetworkCloseEventHandler =
  AnNetworkChangeEventHandler<IconButtonMouseEventHandler>;

type AnNetworkTypeChangeEventHandler =
  AnNetworkChangeEventHandler<SelectChangeEventHandler>;

type AnNetworkInputGroupOptionalProps = {
  showGateway?: boolean;
};

type AnNetworkInputGroupProps = AnNetworkInputGroupOptionalProps & {
  networkId: string;
};

type AnHostInputGroupOptionalProps = {
  hostLabel?: string;
  previous?: Pick<ManifestHost, 'fences' | 'ipmiIp' | 'networks' | 'upses'>;
};

type AnHostInputGroupProps<M extends MapToInputTestID> =
  AnHostInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
    hostId: string;
    hostNumber: number;
    hostType: string;
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
    anSequence: number;
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

/** RunManifestForm */

type RunManifestFormOptionalProps = {
  onSubmitSuccess?: () => void;
};

type RunManifestFormProps = RunManifestFormOptionalProps & {
  detail: APIManifestDetail;
  knownFences: APIManifestTemplateFenceList;
  knownHosts: APIHostOverviewList;
  knownUpses: APIManifestTemplateUpsList;
  tools: CrudListFormTools;
};

type RunManifestHostFormikValues = {
  anvil?: {
    name: string;
    uuid: string;
  };
  number: number;
  type: string;
  uuid: string;
};

type RunManifestFormikValues = {
  confirmPassword: string;
  description: string;
  hosts: Record<string, RunManifestHostFormikValues>;
  password: string;
  rerun: boolean;
  reuseHosts: boolean;
};
