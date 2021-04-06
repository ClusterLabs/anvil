declare type AnvilConnection = {
  protocol: 'async_a' | 'sync_c';
  targets: Array<{
    target_name: string;
    states: {
      connection: string;
      disk: string;
    };
    role: string;
    logical_volume_path: string;
  }>;
  resync?: {
    rate: number;
    percent_complete: number;
    time_remain: number;
  };
};

declare type AnvilVolume = {
  index: number;
  drbd_device_path: string;
  drbd_device_minor: number;
  size: number;
  connections: Array<AnvilConnection>;
};

declare type AnvilResource = {
  resource_name: string;
  volumes: Array<AnvilVolume>;
};

declare type AnvilReplicatedStorage = {
  resources: Array<AnvilResource>;
};
