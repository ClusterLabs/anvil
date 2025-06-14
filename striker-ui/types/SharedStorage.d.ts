type StorageGroupMemberFormikValues = {
  vg: null | string;
};

type StorageGroupFormikValues = {
  hosts: Record<string, StorageGroupMemberFormikValues>;
  name: string;
};

type SharedStorageEditTarget<T> = {
  set: (value?: T) => void;
  value: T;
};

type SharedStorageContentProps<E extends Error = Error> = {
  anvil: string;
  confirm: ConfirmDialogUtils;
  error?: E;
  formDialogRef: React.RefObject<DialogForwardedRefContent | null>;
  loading?: boolean;
  storages?: APIAnvilSharedStorageOverview;
  target: SharedStorageEditTarget<string | undefined>;
};

type StorageGroupProps = {
  formDialogRef: React.RefObject<DialogForwardedRefContent | null>;
  storages: APIAnvilSharedStorageOverview;
  target: SharedStorageEditTarget<string | undefined>;
  uuid: string;
};

type StorageGroupFormOptionalProps = {
  uuid?: string;
};

type StorageGroupFormProps = StorageGroupFormOptionalProps & {
  anvil: string;
  confirm: ConfirmDialogUtils;
  storages: APIAnvilSharedStorageOverview;
};

type StorageGroupMemberFormProps<Values extends StorageGroupFormikValues> = {
  formikUtils: FormikUtils<Values>;
  host: string;
  storages: APIAnvilSharedStorageOverview;
};
