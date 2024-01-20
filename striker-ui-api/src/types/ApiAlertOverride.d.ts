type AlertOverrideOverview = {
  level: number;
  mailRecipient: MailRecipientOverview;
  node: { name: string; uuid: string };
  subnode: { name: string; short: string; uuid: string };
  uuid: string;
};

type AlertOverrideDetail = AlertOverrideOverview;

type AlertOverrideOverviewList = {
  [uuid: string]: AlertOverrideOverview;
};

type AlertOverrideReqQuery = {
  'mail-recipient': string | string[];
};

type AlertOverrideReqParams = {
  uuid: string;
};

type AlertOverrideRequestBody = Pick<AlertOverrideDetail, 'level'> & {
  hostUuid: string;
  mailRecipientUuid: string;
};
