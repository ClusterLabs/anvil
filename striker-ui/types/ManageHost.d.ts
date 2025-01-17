type InquireHostResponse = APICommandInquireHostResponseBody & {
  hostIpAddress: string;
  hostPassword: string;
};

type InquireHostResponseStateSetter = React.Dispatch<
  React.SetStateAction<InquireHostResponse | undefined>
>;

/** TestAccessForm */

type TestAccessFormikValues = {
  ip: string;
  password: string;
};

type TestAccessFormProps = {
  setResponse: InquireHostResponseStateSetter;
  tools: CrudListFormTools;
};

/** PrepareHostForm */

/**
 * @property hostType - Type of host to prepare; note that `node` is `subnode`
 * due to renaming.
 */
type PrepareHostFormikValues = TestAccessFormikValues & {
  enterpriseKey?: string;
  name: string;
  redhatConfirmPassword?: string;
  redhatPassword?: string;
  redhatUsername?: string;
  type: '' | 'dr' | 'subnode';
  uuid: string;
};

type PreapreHostFormProps = {
  host: InquireHostResponse;
  setResponse: InquireHostResponseStateSetter;
  tools: CrudListFormTools;
};

/** HostListItem */

type HostListItemProps = {
  data: APIHostOverview;
};

/** DeleteSshKeyConflictProgress */

type DeleteSshKeyConflictProgressProps = Pick<
  APIDeleteSSHKeyConflictResponseBody,
  'jobs'
> & {
  progress: {
    total: number;
    setTotal: React.Dispatch<React.SetStateAction<number>>;
  };
};

/** ManageHost */

type ManageHostOptionalProps = {
  onValidateHostsChange?: (value: boolean) => void;
};

type ManageHostProps = ManageHostOptionalProps;
