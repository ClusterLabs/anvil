type MailRecipientOverview = {
  name: string;
  uuid: string;
};

type MailRecipientDetail = MailRecipientOverview & {
  email: string;
  language: string;
  level: number;
};

type MailRecipientOverviewList = {
  [uuid: string]: MailRecipientOverview;
};

type MailRecipientParamsDictionary = {
  uuid: string;
};

type MailRecipientRequestBody = Omit<MailRecipientDetail, 'uuid'>;
