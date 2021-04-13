declare type AnvilServer = {
  server_name: string;
  server_uuid: string;
  server_state: string;
  server_host_index: number;
};

declare type AnvilServers = {
  servers: Array<AnvilServer>;
};
