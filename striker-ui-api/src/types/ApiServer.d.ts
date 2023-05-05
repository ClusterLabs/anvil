type ServerOverview = {
  anvilName: string;
  anvilUUID: string;
  serverHostUUID: string;
  serverName: string;
  serverState: string;
  serverUUID: string;
};

type ServerDetailParamsDictionary = {
  serverUUID: string;
};

type ServerDetailParsedQs = {
  ss: boolean | number | string;
  resize: string;
};
