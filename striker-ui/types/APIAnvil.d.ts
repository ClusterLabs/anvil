type AnvilCPU = {
  allocated: number;
  cores: number;
  hosts: {
    [hostUuid: string]: {
      cores: number;
      model: string;
      name: string;
      threads: number;
      uuid: string;
      vendor: string;
    };
  };
  threads: number;
};

type AnvilMemory = {
  allocated: string;
  available: string;
  reserved: string;
  total: string;
};

type AnvilMemoryCalcable = {
  allocated: bigint;
  available: bigint;
  reserved: bigint;
  total: bigint;
};

type AnvilNetworkBondLink = {
  link_name: string;
  link_uuid: string;
  link_speed: number;
  link_state: 'optimal' | 'degraded' | 'down';
  is_active: boolean;
};

type AnvilNetworkHostBond = {
  bond_name: string;
  bond_uuid: string;
  links: AnvilNetworkBondLink[];
};

type AnvilNetworkHosts = {
  host_name: string;
  host_uuid: string;
  bonds: AnvilNetworkHostBond[];
};

type AnvilNetwork = {
  hosts: AnvilNetworkHosts[];
};

type AnvilServer = {
  anvilName: string;
  anvilUUID: string;
  serverName: string;
  serverUUID: string;
  serverState:
    | 'running'
    | 'idle'
    | 'paused'
    | 'in shutdown'
    | 'shut off'
    | 'crashed'
    | 'pmsuspended'
    | 'migrating';
  serverHostUUID: string;
};

type AnvilServers = AnvilServer[];

type AnvilSharedStorageGroup = {
  storage_group_free: string;
  storage_group_name: string;
  storage_group_total: string;
  storage_group_uuid: string;
};

type AnvilSharedStorage = {
  storage_groups: AnvilSharedStorageGroup[];
  total_size: string;
  total_free: string;
};

type AnvilStatusHost = {
  host_name: string;
  host_uuid: string;
  maintenance_mode: boolean;
  server_count: number;
  state: APIHostStatus;
  state_message: string;
  state_percent: number;
};

type AnvilStatus = {
  anvilStatus: {
    drbd: {
      status: string;
      estimatedTimeToSync: number;
    };
    system: string;
  };
  hosts: AnvilStatusHost[];
};

type AnvilListItem = {
  anvil_name: string;
  anvil_uuid: string;
} & AnvilStatus;

type AnvilList = {
  anvils: AnvilListItem[];
};

type APIAnvilOverviewArray = Array<{
  anvilDescription: string;
  anvilName: string;
  anvilUUID: string;
  hosts: Array<{
    hostName: string;
    hostType: string;
    hostUUID: string;
  }>;
}>;

type APIAnvilOverview = {
  description: string;
  hosts: {
    [uuid: string]: {
      name: string;
      type: string;
      uuid: string;
    };
  };
  name: string;
  uuid: string;
};

type APIAnvilDetail = {
  hosts: {
    [uuid: string]: {
      maintenance: boolean;
      name: string;
      serverCount: number;
      state: AnvilStatusHost['state'];
      stateProgress: number;
      uuid: string;
    };
  };
  name: string;
  status: {
    drbd: {
      status: string;
      estimatedTimeToSync: number;
    };
    system: string;
  };
  uuid: string;
};

type APIAnvilOverviewList = {
  [uuid: string]: APIAnvilOverview;
};

type APIAnvilStorageGroupCalcable = {
  free: bigint;
  name: string;
  size: bigint;
  used: bigint;
  uuid: string;
};

type APIAnvilSharedStorageOverview = {
  storageGroups: {
    [uuid: string]: APIAnvilStorageGroupCalcable;
  };
  totalFree: bigint;
  totalSize: bigint;
  totalUsed: bigint;
};
