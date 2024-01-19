type AlertOverrideOverview = {
  level: number;
  host: HostOverview;
  mailRecipient: MailRecipientOverview;
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
