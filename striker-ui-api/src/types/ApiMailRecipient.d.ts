type MailRecipientOverview = {
  email: string;
  level: number;
  name: string;
  uuid: string;
};

type MailRecipientDetail = MailRecipientOverview & {
  language: string;
};

type MailRecipientOverviewList = Record<string, MailRecipientOverview>;

type MailRecipientParamsDictionary = {
  uuid: string;
};

type MailRecipientRequestBody = Omit<MailRecipientDetail, 'uuid'>;

type MailRecipientResponseBody = Pick<MailRecipientDetail, 'uuid'>;
