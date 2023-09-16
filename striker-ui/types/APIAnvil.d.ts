type AnvilCPU = {
  allocated: number;
  cores: number;
  threads: number;
};

type AnvilMemory = {
  allocated: string;
  reserved: string;
  total: string;
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
};

type AnvilStatusHost = {
  state: 'offline' | 'booted' | 'crmd' | 'in_ccm' | 'online';
  host_uuid: string;
  host_name: string;
  state_percent: number;
  state_message: string;
  removable: boolean;
};

type AnvilStatus = {
  anvil_state: 'optimal' | 'not_ready' | 'degraded';
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
  anvilName: string;
  anvilUUID: string;
  hosts: Array<{ hostName: string; hostUUID: string }>;
}>;

type APIAnvilOverview = {
  hosts: {
    [uuid: string]: {
      name: string;
      uuid: string;
    };
  };
  name: string;
  uuid: string;
};

type APIAnvilOverviewList = {
  [uuid: string]: APIAnvilOverview;
};
