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
  resize: string;
  ss: boolean | number | string;
  vnc: boolean | number | string;
};

type ServerDetail = {
  anvil: {
    description: string;
    name: string;
    uuid: string;
  };
  name: string;
  host: {
    name: string;
    short: string;
    type: string;
    uuid: string;
  };
  state: string;
  uuid: string;
};

type ServerDetailScreenshot = {
  screenshot: string;
  timestamp: number;
};

type ServerDetailVncInfo = {
  domain: string;
  port: number;
  protocol: string;
};

type ServerRenameRequestBody = {
  newName: string;
};

type ServerUpdateParamsDictionary = {
  uuid: string;
};

type ServerUpdateResponseBody = {
  jobUuid: string;
};
