declare type AnvilListItem = {
  anvil_name: string;
  anvil_uuid: string;
  nodes: Array<{
    node_name: string;
    node_uuid: string;
  }>;
};
