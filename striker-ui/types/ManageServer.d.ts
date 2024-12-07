type ServerAddDiskFormikValues = {
  size: {
    unit: string;
    value: string;
  };
  storage: string;
};

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

type ServerChangeIsoFormikValues = {
  file: null | string;
};

type ServerRenameFormikValues = {
  name: string;
};

type ServerMemoryFormikValues = {
  size: {
    unit: import('format-data-size').DataSizeUnit;
    value: string;
  };
};

/**
 * @property delay - Unit: seconds
 */
type ServerStartDependencyFormikValues = {
  active: boolean;
  after: string;
  delay: string;
};

/** ManageServer */

type ManageServerOptionalProps = {
  slotProps?: {
    preview?: {
      onClick?: React.MouseEventHandler<HTMLButtonElement>;
    };
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

/** ServerDiskList */

type ServerDiskListProps = ServerFormProps;

/** ServerInterfaceList */

type ServerInterfaceListProps = ServerFormProps;

/** ServerMigration */

type ServerMigrationProps = ServerFormProps;

/** ServerMigrationTable */

type ServerMigrationTableProps = ServerFormProps & {
  servers: APIServerOverviewList;
};

/** ServerAddDiskForm */

type ServerAddDiskFormProps = ServerFormProps & {
  device?: string;
};

/** ServerAddInterfaceForm */

type ServerAddInterfaceFormProps = ServerFormProps;

/** ServerBootOrderForm */

type ServerBootOrderFormProps = ServerFormProps;

/** ServerChangeIsoForm */

type ServerIsoSummaryProps = {
  fileUuid: string;
};

type ServerChangeIsoFormProps = ServerFormProps & {
  device: string;
};

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
