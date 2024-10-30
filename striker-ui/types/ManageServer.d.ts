type ServerBootOrderFormikValues = {
  boot: {
    order: number[];
  };
};

type ServerCpuFormikValues = {
  cpu: {
    clusters: string;
    cores: string;
    dies: string;
    sockets: string;
    threads: string;
  };
};

type ServerNameFormikValues = {
  name: string;
};

type ServerMemoryFormikValues = {
  memory: {
    size: string;
    unit: import('format-data-size').DataSizeUnit;
  };
};

/**
 * @property start.delay - Unit: seconds
 */
type ServerStartDependencyFormikValues = {
  start: {
    after: string;
    delay: number;
  };
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

/** ServerBootOrderForm */

type ServerBootOrderFormProps = ServerFormProps;

/** ServerCpuForm */

type ServerCpuFormProps = ServerFormProps;

/** ServerNameForm */

type ServerNameFormProps = ServerFormProps;

/** ServerMemoryForm */

type ServerMemoryFormProps = ServerFormProps;

/** ServerStartDependencyForm */

type ServerStartDependencyFormProps = ServerFormProps & {
  servers: APIServerOverviewList;
};
