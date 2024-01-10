type MailServerOverview = {
  address: string;
  port: number;
  uuid: string;
};

type MailServerDetail = MailServerOverview & {
  authentication: string;
  heloDomain: string;
  password?: string;
  security: string;
  username?: string;
};

type MailServerOverviewList = {
  [uuid: string]: MailServerOverview;
};

type MailServerParamsDictionary = {
  uuid: string;
};

type MailServerRequestBody = Omit<MailServerDetail, 'uuid'>;
