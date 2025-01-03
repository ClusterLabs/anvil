type ServerGroups = {
  match: string[];
  none: string[];
};

type ServerListItemProps = {
  anvils: APIAnvilOverviewList;
  servers: APIServerOverviewList;
  uuid: string;
};

type ServerListProps = {
  groups: ServerGroups;
  servers: APIServerOverviewList;
};

type ServerPanelsProps = {
  groups: ServerGroups;
  servers: APIServerOverviewList;
};
