declare type AnvilSharedStorageNode = {
  is_mounted: boolean;
  total: number;
  free: number;
  nodeInfo?: AnvilListItemNode;
};

declare type AnvilSharedStorageFileSystem = {
  mount_point: string;
  nodes: Array<AnvilSharedStorageNode>;
};

declare type AnvilSharedStorage = {
  file_systems: Array<AnvilSharedStorageFileSystem>;
};
