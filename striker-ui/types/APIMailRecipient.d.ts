type APIMailRecipientOverview = {
  email: string;
  level: number;
  name: string;
  uuid: string;
};

type APIMailRecipientOverviewList = Record<string, APIMailRecipientOverview>;

type APIMailRecipientDetail = APIMailRecipientOverview & {
  language: string;
};
