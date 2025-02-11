type ProvisionServerDiskFormikValues = {
  size: {
    unit: import('format-data-size').DataSizeUnit;
    value: string;
  };
  storageGroup: null | string;
};

type ProvisionServerFormikValues = {
  cpu: {
    cores: null | string;
  };
  disks: Record<string, ProvisionServerDiskFormikValues>;
  driver: null | string;
  install: null | string;
  memory: {
    unit: import('format-data-size').DataSizeUnit;
    value: string;
  };
  name: string;
  node: null | string;
  os: null | string;
};

type ProvisionServerScopeGroup = {
  node: string;
  storageGroup: string;
};

type ProvisionServerScope = ProvisionServerScopeGroup[];

type ProvisionServerFormProps = {
  lsos: APIServerOses;
  resources: ProvisionServerResources;
};

type MaxButtonOptionalProps = Pick<ContainedButtonProps, 'onClick'> & {
  slotProps?: {
    button: ContainedButtonProps;
  };
};

type MaxButtonProps = MaxButtonOptionalProps & {
  max: string;
};

type ProvisionServerDiskProps = Pick<ProvisionServerFormProps, 'resources'> & {
  formikUtils: FormikUtils<ProvisionServerFormikValues>;
  id: string;
  scope: React.MutableRefObject<ProvisionServerScope>;
};

type ProvisionServerExistingListProps = Pick<
  ProvisionServerFormProps,
  'resources'
>;

type ProvisionServerSummary = Pick<
  ProvisionServerFormProps,
  'lsos' | 'resources'
> & {
  values: ProvisionServerFormikValues;
};
