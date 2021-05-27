declare type HostSet = {
  host_uuid: string;
};

declare type HostSetPower = HostSet & {
  is_on: boolean;
};

declare type HostSetMembership = HostSet & {
  is_membership: boolean;
};
