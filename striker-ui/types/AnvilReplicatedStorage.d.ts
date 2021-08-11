declare type AnvilConnection = {
  protocol: 'async_a' | 'sync_c';
  connection_state: string;
  fencing: string;
  targets: Array<{
    target_name: string;
    target_host_uuid: string;
    disk_state: string;
    role: string;
    logical_volume_path?: string;
  }>;
  resync?: {
    rate: number;
    percent_complete: number;
    time_remain: number;
    oos_size: number;
  };
};

declare type AnvilVolume = {
  number: number;
  drbd_device_path: string;
  drbd_device_minor: number;
  size: number;
  connections: Array<AnvilConnection>;
};

declare type AnvilReplicatedStorage = {
  resource_name: string;
  resource_host_uuid: string;
  is_active: boolean;
  timestamp: number;
  volumes: Array<AnvilVolume>;
};
