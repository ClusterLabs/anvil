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

type AnIdInputGroupProps = {
  slotProps?: {
    container?: import('@mui/material/Grid2').Grid2Props;
  };
};

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

type AnNetworkInputGroupProps = {
  networkId: string;
  showGateway?: boolean;
};

type AnHostInputGroupProps = {
  hostSequence: string;
  knownFences: APIManifestTemplateFenceList;
  knownUpses: APIManifestTemplateUpsList;
};

type AnNetworkConfigInputGroupProps = {
  slotProps?: {
    container?: import('@mui/material/Grid2').Grid2Props;
  };
};

type AnHostConfigInputGroupProps = Pick<
  AnHostInputGroupProps,
  'knownFences' | 'knownUpses'
>;

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
