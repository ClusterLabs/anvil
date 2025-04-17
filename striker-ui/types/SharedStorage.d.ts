type StorageGroupMemberFormikValues = {
  vg: null | string;
};

type StorageGroupFormikValues = {
  hosts: Record<string, StorageGroupMemberFormikValues>;
  name: string;
};

type SharedStorageContentProps<E extends Error = Error> = {
  error?: E;
  formDialogRef: React.RefObject<DialogForwardedRefContent>;
  loading?: boolean;
  storages?: APIAnvilSharedStorageOverview;
};

type StorageGroupProps = {
  storages: APIAnvilSharedStorageOverview;
  uuid: string;
};

type StorageGroupFormOptionalProps = {
  uuid?: string;
};

type StorageGroupFormProps = StorageGroupFormOptionalProps & {
  storages: APIAnvilSharedStorageOverview;
};

type StorageGroupMemberFormProps<Values extends StorageGroupFormikValues> = {
  formikUtils: FormikUtils<Values>;
  host: string;
  storages: APIAnvilSharedStorageOverview;
  vgs: string[];
};
