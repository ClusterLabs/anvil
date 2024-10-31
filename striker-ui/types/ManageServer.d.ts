type ServerInterfaceFormikValues = {
  bridge: string;
  mac: string;
  model: null | string;
};

type ServerBootOrderFormikValues = {
  order: number[];
};

type ServerCpuFormikValues = {
  clusters: string;
  cores: string;
  dies: string;
  sockets: string;
  threads: string;
};

type ServerRenameFormikValues = {
  name: string;
};

type ServerMemoryFormikValues = {
  size: string;
  unit: import('format-data-size').DataSizeUnit;
};

/**
 * @property delay - Unit: seconds
 */
type ServerStartDependencyFormikValues = {
  after: string;
  delay: string;
};

/** ManageServer */

type ManageServerOptionalProps = {
  slotProps?: {
    preview?: Pick<import('@mui/material').IconButtonProps, 'onClick'>;
  };
};

type ManageServerProps = ManageServerOptionalProps & {
  serverUuid: string;
};

type ServerFormProps = {
  detail: APIServerDetail;
  tools: CrudListFormTools;
};

/** ServerFormGrid */

type ServerFormGridProps<Values extends FormikValues> =
  import('@mui/material').GridProps & {
    formik: Formik<Values>;
  };

/** ServerFormSubmit */

type ServerFormSubmitProps = {
  detail: APIServerDetail;
  formDisabled: boolean;
  label: React.ReactNode;
};

/** ServerInterfaceList */

type ServerInterfaceListProps = ServerFormProps;

/** ServerMigrateTable */

type ServerMigrateTableProps = ServerFormProps & {
  servers: APIServerOverviewList;
};

/** ServerAddInterfaceForm */

type ServerAddInterfaceFormProps = {
  detail: APIServerDetail;
};

/** ServerBootOrderForm */

type ServerBootOrderFormProps = ServerFormProps;

/** ServerCpuForm */

type BaseServerCpuFormProps = ServerFormProps & {
  cpu: AnvilCPU;
};

type ServerCpuFormProps = ServerFormProps;

/** ServerRenameForm */

type ServerRenameFormProps = ServerFormProps & {
  servers: APIServerOverviewList;
};

/** ServerMemoryForm */

type BaseServerMemoryFormProps = ServerFormProps & {
  memory: AnvilMemoryCalcable;
};

type ServerMemoryFormProps = ServerFormProps;

/** ServerStartDependencyForm */

type ServerStartDependencyFormProps = ServerFormProps & {
  servers: APIServerOverviewList;
};
