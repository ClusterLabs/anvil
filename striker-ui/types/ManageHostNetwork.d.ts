type PrepareHostNetworkFormikValues = HostNetInitFormikExtension & {
  hostName: string;
  mini: boolean;
};

/** HostTabs */

type HostTabsProps = {
  list: APIHostOverview[];
  setValue: (value: string) => void;
  value: false | string;
};

/** PrepareHostNetwork */

type PrepareHostNetworkProps = {
  uuid: string;
};

/** PrepareHostNetworkForm */

type PrepareHostNetworkFormProps = {
  detail: APIHostDetail;
  tools: CrudListFormTools;
  uuid: string;
};

/** PrepareHostNetworkSummary */

type PrepareHostNetworkSummaryProps = {
  gatewayIface: string;
  ifaces: APINetworkInterfaceOverviewList;
  values: PrepareHostNetworkFormikValues;
};
