type APIAlertOverrideOverview = {
  level: number;
  mailRecipient: APIMailRecipientOverview;
  node: { name: string; uuid: string };
  subnode: { name: string; short: string; uuid: string };
  uuid: string;
};

type APIAlertOverrideOverviewList = {
  [uuid: string]: APIAlertOverrideOverview;
};
