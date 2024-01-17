type APIMailServerOverview = Pick<
  MailServerFormikMailServer,
  'address' | 'port' | 'uuid'
>;

type APIMailServerOverviewList = {
  [uuid: string]: APIMailServerOverview;
};

type APIMailServerDetail = MailServerFormikMailServer;
