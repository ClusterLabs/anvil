declare type NodeSet = {
  host_uuid: string;
};

declare type NodeSetPower = NodeSet & {
  is_on: boolean;
};

declare type NodeSetMembership = NodeSet & {
  is_membership: boolean;
};
