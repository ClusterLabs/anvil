type AnvilDetailCpuHost = {
  cores: number;
  model: string;
  name: string;
  threads: number;
  uuid: string;
  vendor: string;
};

type AnvilDetailCpuHostList = {
  [hostUuid: string]: AnvilDetailCpuHost;
};

type AnvilDetailCpuSummary = {
  allocated: number;
  cores: number;
  hosts: AnvilDetailCpuHostList;
  threads: number;
};

type AnvilDetailFileForProvisionServer = {
  fileUUID: string;
  fileName: string;
};

type AnvilDetailHostForProvisionServer = {
  hostUUID: string;
  hostName: string;
  hostCPUCores: number;
  hostMemory: string;
};

type AnvilDetailHostMemory = {
  free: string;
  host_uuid: string;
  swap_free: string;
  swap_total: string;
  total: string;
};

type AnvilDetailServerForProvisionServer = {
  serverUUID: string;
  serverName: string;
  serverCPUCores: number;
  serverMemory: string;
};

type AnvilDetailStore = {
  storage_group_free: string;
  storage_group_name: string;
  storage_group_total: string;
  storage_group_uuid: string;
};

type AnvilDetailStoreForProvisionServer = {
  storageGroupUUID: string;
  storageGroupName: string;
  storageGroupSize: string;
  storageGroupFree: string;
};

type AnvilDetailSubnodeLink = {
  is_active: boolean;
  link_name: string;
  link_speed: number;
  link_state: string;
  link_uuid: string;
};

type AnvilDetailSubnodeBond = {
  active_interface: string;
  bond_name: string;
  bond_uuid: string;
  links: AnvilDetailSubnodeLink[];
};

type AnvilDetailSubnodeNetwork = {
  bonds: AnvilDetailSubnodeBond[];
  host_name: string;
  host_uuid: string;
};

// Types below are for typing request handlers:

type AnvilDetailHostSummary = {
  host_name: string;
  host_uuid: string;
  maintenance_mode: boolean;
  server_count: number;
  state: string;
  state_message: string;
  state_percent: number;
};

type AnvilDetailSummary = {
  anvil_name: string;
  anvil_state: string;
  anvil_uuid: string;
  hosts: AnvilDetailHostSummary[];
};

/**
 * @deprecated
 */
type AnvilSummary = { anvils: AnvilDetailSummary[] };

type AnvilDetailForProvisionServer = {
  anvilDescription: string;
  anvilName: string;
  anvilTotalAllocatedCPUCores: number;
  anvilTotalAllocatedMemory: string;
  anvilTotalAvailableCPUCores: number;
  anvilTotalAvailableMemory: string;
  anvilTotalCPUCores: number;
  anvilTotalMemory: string;
  anvilUUID: string;
  files: AnvilDetailFileForProvisionServer[];
  hosts: AnvilDetailHostForProvisionServer[];
  servers: AnvilDetailServerForProvisionServer[];
  storageGroups: AnvilDetailStoreForProvisionServer[];
};

type AnvilDetailNetworkSummary = {
  hosts: AnvilDetailSubnodeNetwork[];
};

type AnvilDetailParamsDictionary = {
  anvilUuid: string;
};

type AnvilDetailStoreSummary = {
  storage_groups: AnvilDetailStore[];
  total_free: string;
  total_size: string;
};

/**
 * @prop replication.state - also known as local disk state in the tables
 * @prop connection.estimatedTimeToSync - unit: seconds
 */
type AnvilOverviewHostDrbdResource = {
  connection: {
    state: string;
  };
  name: string;
  replication: {
    estimatedTimeToSync: number;
    state: string;
  };
  uuid: string;
};

type AnvilOverviewHost = {
  hostClusterMembership: string;
  hostDrbdResources: Record<string, AnvilOverviewHostDrbdResource>;
  hostName: string;
  hostStatus: string;
  hostType: string;
  hostUUID: string;
};

type AnvilOverview = {
  anvilDescription: string;
  anvilName: string;
  anvilStatus: {
    drbd: {
      status: string;
      maxEstimatedTimeToSync: number;
    };
    system: string;
  };
  anvilUUID: string;
  hosts: AnvilOverviewHost[];
};
