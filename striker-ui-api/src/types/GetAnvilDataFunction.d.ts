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
