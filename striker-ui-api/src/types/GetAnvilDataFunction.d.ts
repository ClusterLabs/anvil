interface AnvilDataStruct {
  [key: string]: AnvilDataStruct | boolean;
}

type AnvilDataAnvilListHash = {
  anvil_uuid: {
    [uuid: string]: {
      anvil_description: string;
      anvil_node1_host_uuid: string;
      anvil_node2_host_uuid: string;
      query_time: number;
    };
  };
  host_uuid: {
    [uuid: string]: {
      anvil_name: string;
      anvil_uuid: string;
      role: string;
    };
  };
};

type AnvilDataDatabaseHash = {
  [hostUUID: string]: {
    host: string;
    name: string;
    password: string;
    ping: string;
    port: string;
    user: string;
  };
};

type AnvilDataHostListHash = {
  host_uuid: {
    [hostUuid: string]: {
      anvil_name?: string;
      anvil_uuid?: string;
      host_ipmi: string;
      host_key: string;
      host_name: string;
      host_status: string;
      host_type: string;
      short_host_name: string;
    };
  };
};

type AnvilDataManifestListHash = {
  manifest_uuid: {
    [manifestUUID: string]: {
      parsed: {
        domain: string;
        fences?: {
          [fenceId: string]: {
            uuid: string;
          };
        };
        machine: {
          [hostId: string]: {
            fence?: {
              [fenceName: string]: {
                port: string;
              };
            };
            ipmi_ip: string;
            name: string;
            network: {
              [networkId: string]: {
                ip: string;
              };
            };
            ups?: {
              [upsName: string]: {
                used: string;
              };
            };
          };
        };
        name: string;
        networks: {
          count: {
            [networkType: string]: number;
          };
          dns: string;
          mtu: string;
          name: {
            [networkId: string]: {
              gateway: string;
              network: string;
              subnet: string;
            };
          };
          ntp: string;
        };
        prefix: string;
        sequence: string;
        upses?: {
          [upsId: string]: {
            uuid: string;
          };
        };
      };
    };
  };
  name_to_uuid: Record<string, string>;
} & Record<
  string,
  {
    manifest_last_ran: number;
    manifest_name: string;
    manifest_note: string;
    manifest_xml: string;
  }
>;

type AnvilDataSysHash = {
  hosts?: {
    by_uuid: { [hostUuid: string]: string };
    by_name: { [hostName: string]: string };
  };
};

type AnvilDataUPSHash = {
  [upsName: string]: {
    agent: string;
    brand: string;
    description: string;
  };
};

type GetAnvilDataOptions = {
  predata?: Array<[string, ...unknown[]]>;
};
