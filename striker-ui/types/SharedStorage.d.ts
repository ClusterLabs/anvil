type SharedStorageContentProps<E extends Error = Error> = {
  error?: E;
  loading?: boolean;
  storage?: APIAnvilSharedStorageOverview;
};

type StorageGroupProps = {
  storageGroup: APIAnvilStorageGroupCalcable;
};
