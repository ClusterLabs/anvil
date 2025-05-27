type InquireHostResponse = APICommandInquireHostResponseBody & {
  hostPassword: string;
  target: string;
};

type InquireHostResponseStateSetter = React.Dispatch<
  React.SetStateAction<InquireHostResponse | undefined>
>;

/** TestAccessForm */

type TestAccessFormikValues = {
  password: string;
  target: string;
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

/** ManageHostList */

type ManageHostListOptionalProps = {
  onValidateHostsChange?: (value: boolean) => void;
};

type ManageHostListProps = ManageHostListOptionalProps;

/** ManageHost */

type ManageHostProps = {
  uuid: string;
};

type HostTabCommonProps = {
  host: APIHostDetailCalcable;
};

type HostGeneralInfoProps = HostTabCommonProps;

type HostServerListProps = HostTabCommonProps;

type HostStorageListProps = HostTabCommonProps;
