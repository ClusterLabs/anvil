type NodeMinimum = {
  name: string;
  description: string;
  uuid: string;
};

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
    shortHostName: string;
  }>;
}>;

type APIAnvilOverview = {
  description: string;
  hosts: {
    [uuid: string]: {
      name: string;
      short: string;
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

type APIAnvilStorageHost = {
  name: string;
  short: string;
  uuid: string;
};

type APIAnvilVolumeGroup = {
  free: string;
  host: string;
  internalUuid: string;
  name: string;
  size: string;
  used: string;
  uuid: string;
};

type APIAnvilStorageGroupMember = {
  volumeGroup: string;
  uuid: string;
};

type APIAnvilStorageGroup = {
  free: string;
  members: Record<string, APIAnvilStorageGroupMember>;
  name: string;
  size: string;
  used: string;
  uuid: string;
};

type APIAnvilStorageList = {
  hosts: Record<string, APIAnvilStorageHost>;
  storageGroupTotals: {
    free: string;
    size: string;
    used: string;
  };
  storageGroups: Record<string, APIAnvilStorageGroup>;
  unusedVolumeGroups: string[];
  volumeGroups: Record<string, APIAnvilVolumeGroup>;
};

type APIAnvilVolumeGroupCalcable = {
  free: bigint;
  host: string;
  internalUuid: string;
  name: string;
  size: bigint;
  used: bigint;
  uuid: string;
};

type APIAnvilStorageGroupMemberCalcable = {
  volumeGroup: string;
  uuid: string;
};

type APIAnvilStorageGroupCalcable = {
  free: bigint;
  members: Record<string, APIAnvilStorageGroupMemberCalcable>;
  name: string;
  size: bigint;
  used: bigint;
  uuid: string;
};

type APIAnvilSharedStorageOverview = {
  hosts: Record<string, APIAnvilStorageHost>;
  storageGroups: Record<string, APIAnvilStorageGroupCalcable>;
  totalFree: bigint;
  totalSize: bigint;
  totalUsed: bigint;
  unusedVolumeGroups: string[];
  volumeGroups: Record<string, APIAnvilVolumeGroupCalcable>;
};
