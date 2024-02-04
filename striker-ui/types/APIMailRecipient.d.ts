type APIMailRecipientOverview = { name: string; uuid: string };

type APIMailRecipientOverviewList = {
  [uuid: string]: APIMailRecipientOverview;
};

type APIMailRecipientDetail = APIMailRecipientOverview & {
  email: string;
  language: string;
  level: number;
};
