type GetAnvilDataOptions = import('child_process').SpawnSyncOptions & {
  predata?: Array<[string, ...unknown[]]>;
};
