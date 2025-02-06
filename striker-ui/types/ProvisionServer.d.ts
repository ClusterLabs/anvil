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

type ProvisionServerDialogContextValue = {
  setLoading?: React.Dispatch<React.SetStateAction<boolean>>;
  setValidating?: React.Dispatch<React.SetStateAction<boolean>>;
};

type ProvisionServerFormProps = {
  lsos: APIServerOses;
  resources: ProvisionServerResources;
};

type ProvisionServerDiskProps = Pick<ProvisionServerFormProps, 'resources'> & {
  formikUtils: FormikUtils<ProvisionServerFormikValues>;
  id: string;
  storageGroups: {
    uuids: string[];
  };
};
