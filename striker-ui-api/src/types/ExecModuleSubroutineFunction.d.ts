type ExecModuleSubroutineOptions = {
  spawnSyncOptions?: import('child_process').SpawnSyncOptions;
  subModuleName?: string;
  subParams?: Record<string, unknown>;
};
