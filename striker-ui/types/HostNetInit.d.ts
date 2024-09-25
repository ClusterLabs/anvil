type HostNetFormikValues = {
  interfaces: [string, string];
  ip: string;
  sequence: string;
  subnetMask: string;
  type: string;
};

type HostNetInitFormikValues = {
  dns: string;
  gateway: string;
  networks: Record<string, HostNetFormikValues>;
};

type HostNetInitFormikExtension = {
  networkInit: HostNetInitFormikValues;
};

type HostNetInitHost = {
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
    formikUtils: FormikUtils<Values>;
    ifaces: APINetworkInterfaceOverviewList;
    ifacesApplied: Record<string, boolean>;
    ifacesValue: APINetworkInterfaceOverview[];
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

/** SimpleIface */

type SimpleIfaceOptionalProps = {
  boxProps?: import('@mui/material').BoxProps;
};

type SimpleIfaceProps = SimpleIfaceOptionalProps & {
  iface: APINetworkInterfaceOverview;
};

type AppliedIfaceProps = SimpleIfaceProps & {
  onClose: React.MouseEventHandler<HTMLButtonElement>;
};
