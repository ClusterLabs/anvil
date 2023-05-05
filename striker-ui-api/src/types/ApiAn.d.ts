type AnvilDetailHostMemory = {
  free: number;
  host_uuid: string;
  swap_free: number;
  swap_total: number;
  total: number;
};

type AnvilDetailHostSummary = {
  host_name: string;
  host_uuid: string;
  maintenance_mode: boolean;
  state: string;
  state_message: string;
  state_percent: number;
};

type AnvilDetailParamsDictionary = {
  anvilUuid: string;
};

type AnvilDetailResponseBody = {
  anvil_state: string;
  hosts: AnvilDetailHostSummary[];
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

type AnvilDetailServerForProvisionServer = {
  serverUUID: string;
  serverName: string;
  serverCPUCores: number;
  serverMemory: string;
};

type AnvilDetailStoreForProvisionServer = {
  storageGroupUUID: string;
  storageGroupName: string;
  storageGroupSize: string;
  storageGroupFree: string;
};

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

type AnvilOverview = {
  anvilName: string;
  anvilUUID: string;
  hosts: Array<{
    hostName: string;
    hostUUID: string;
  }>;
};
