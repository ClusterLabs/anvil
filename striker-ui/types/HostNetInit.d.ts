type HostNetFormikValues = {
  interfaces: [string, string];
  ip: string;
  required?: boolean;
  sequence: string;
  subnetMask: string;
  type: string;
};

type HostNetInitFormikValues = {
  dns: string;
  gateway: string;
  networks: Record<string, HostNetFormikValues>;
  ntp: string;
};

type HostNetInitFormikExtension = {
  networkInit: HostNetInitFormikValues;
};

type HostNetInitHost = {
  parentSequence: number;
  sequence: number;
  type: string;
  uuid: string;
};

/** HostNetInputGroup */

type HostNetInputGroupOptionalProps = {
  hostNetValueId?: string;
  ifaceHeld?: string;
};

type HostNetInputGroupProps<Values extends HostNetInitFormikExtension> =
  HostNetInputGroupOptionalProps & {
    appliedIfaces: Record<string, boolean>;
    formikUtils: FormikUtils<Values>;
    ifaces: APINetworkInterfaceOverviewList;
    ifaceValues: APINetworkInterfaceOverview[];
    host: HostNetInitHost;
    netId: string;
  };

/** HostNetInitInputGroup */

type DragPosition = {
  x: number;
  y: number;
};

type HostNetInitInputGroupOptionalProps = {
  onFetchSuccess?: (data: APINetworkInterfaceOverviewList) => void;
};

type HostNetInitInputGroupProps<Values extends HostNetInitFormikExtension> =
  HostNetInitInputGroupOptionalProps & {
    formikUtils: FormikUtils<Values>;
    host: HostNetInitHost;
  };

/** HostNetSummary */

type HostNetSummaryProps<Values extends HostNetInitFormikExtension> = {
  gatewayIface: string;
  ifaces: APINetworkInterfaceOverviewList;
  values: Values;
};

/** SimpleIface */

type SimpleIfaceOptionalProps = {
  boxProps?: import('@mui/material/Box').BoxProps;
};

type SimpleIfaceProps = SimpleIfaceOptionalProps & {
  iface: APINetworkInterfaceOverview;
};

type AppliedIfaceProps = SimpleIfaceProps & {
  onClose: React.MouseEventHandler<HTMLButtonElement>;
};
