type SharedStorageContentProps<E extends Error = Error> = {
  error?: E;
  loading?: boolean;
  storages?: APIAnvilSharedStorageOverview;
};

type StorageGroupProps = {
  storageGroup: APIAnvilStorageGroupCalcable;
};
