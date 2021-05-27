declare type AnvilServer = {
  server_name: string;
  server_uuid: string;
  server_state:
    | 'running'
    | 'idle'
    | 'paused'
    | 'in_shutdown'
    | 'shut_off'
    | 'crashed'
    | 'pmsuspended'
    | 'migrating';
  server_host_uuid: string;
};

declare type AnvilServers = {
  servers: Array<AnvilServer>;
};
