declare type AnvilListItemNode = {
  node_name: string;
  node_uuid: string;
};

declare type AnvilListItem = {
  anvil_name: string;
  anvil_uuid: string;
  anvil_state: string;
  nodes: Array<AnvilListItemNode>;
};

declare type AnvilList = {
  anvils: Array<AnvilListItem>;
};
