declare type AnvilSharedStorageGroup = {
  storage_group_name: string;
  storage_group_uuid: string;
  storage_group_total: number;
  storage_group_free: number;
};

declare type AnvilSharedStorage = {
  storage_groups: Array<AnvilSharedStorageGroup>;
};
