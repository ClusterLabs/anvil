type StrikerInitFormikValues = HostNetInitFormikExtension & {
  adminPassword: string;
  confirmAdminPassword: string;
  domainName: string;
  hostName: string;
  hostNumber: string;
  organizationName: string;
  organizationPrefix: string;
};

/** StrikerInitForm */

type StrikerInitFormOptionalProps = {
  detail?: APIHostDetail;
  onSubmitSuccess?: (data: APIStrikerInitResponseBody) => void;
};

type StrikerInitFormProps = StrikerInitFormOptionalProps & {
  tools: CrudListFormTools;
};

/** StrikerInitProgress */

type StrikerInitProgressProps = {
  jobUuid: string;
  reinit: boolean;
};

/** StrikerInitSummary */

type StrikerInitSummaryProps = {
  gatewayIface: string;
  ifaces: APINetworkInterfaceOverviewList;
  values: StrikerInitFormikValues;
};
