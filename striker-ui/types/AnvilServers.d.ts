declare type AnvilServers = {
  servers: Array<{
    server_name: string;
    server_uuid: string;
    server_state: string;
    server_host_index: number;
  }>;
};
