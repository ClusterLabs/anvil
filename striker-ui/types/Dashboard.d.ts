type ServerGroups = {
  match: string[];
  none: string[];
};

type ServerPanelsProps = {
  groups: ServerGroups;
  servers: APIServerOverviewList;
};
