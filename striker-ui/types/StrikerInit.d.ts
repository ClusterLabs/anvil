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
  ipRef?: React.RefObject<string>;
  onSubmitSuccess?: (data: APIStrikerInitResponseBody) => void;
};

type StrikerInitFormProps = StrikerInitFormOptionalProps & {
  tools: CrudListFormTools;
};

/** StrikerInitProgress */

type StrikerInitProgressProps = {
  ipRef?: React.RefObject<string>;
  jobUuid: string;
  reinit: boolean;
};

/** StrikerInitSummary */

type StrikerInitSummaryProps = HostNetSummaryProps<StrikerInitFormikValues>;
