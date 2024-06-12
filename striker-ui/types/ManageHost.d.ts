type InquireHostResponse = APICommandInquireHostResponseBody & {
  hostIpAddress: string;
  hostPassword: string;
};

/** TestAccessForm */

type TestAccessFormikValues = {
  ip: string;
  password: string;
};

type TestAccessFormProps = {
  setResponse: React.Dispatch<
    React.SetStateAction<InquireHostResponse | undefined>
  >;
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
  tools: CrudListFormTools;
};

/** HostListItem */

type HostListItemProps = {
  data: APIHostOverview;
};
