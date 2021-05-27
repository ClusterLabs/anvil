declare type AnvilSharedStorageHost = {
  host_uuid: string;
  host_name: string;
  is_mounted: boolean;
  total: number;
  free: number;
};

declare type AnvilSharedStorageFileSystem = {
  mount_point: string;
  hosts: Array<AnvilSharedStorageHost>;
};

declare type AnvilSharedStorage = {
  file_systems: Array<AnvilSharedStorageFileSystem>;
};
