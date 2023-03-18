interface AnvilDataStruct {
  [key: string]: AnvilDataStruct | boolean;
}

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

type AnvilDataUPSHash = {
  [upsName: string]: {
    agent: string;
    brand: string;
    description: string;
  };
};

type GetAnvilDataOptions = import('child_process').SpawnSyncOptions & {
  predata?: Array<[string, ...unknown[]]>;
};
