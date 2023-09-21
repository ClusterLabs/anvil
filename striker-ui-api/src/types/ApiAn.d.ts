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
};

type AnvilOverview = {
  anvilDescription: string;
  anvilName: string;
  anvilUUID: string;
  hosts: Array<{
    hostName: string;
    hostType: string;
    hostUUID: string;
  }>;
};
