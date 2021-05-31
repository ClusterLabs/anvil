declare type AnvilFileSystemHost = {
  host_uuid: string;
  host_name: string;
  is_mounted: boolean;
  total: number;
  free: number;
};

declare type AnvilFileSystem = {
  mount_point: string;
  hosts: Array<AnvilFileSystemHost>;
};

declare type AnvilFileSystems = {
  file_systems: Array<AnvilFileSystem>;
};
