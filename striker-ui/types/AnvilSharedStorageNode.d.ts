declare type AnvilSharedStorageNode = {
  is_mounted: boolean;
  total: number;
  free: number;
  nodeInfo?: {
    node_name: string;
    node_uuid: string;
  };
};
