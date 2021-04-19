declare type AnvilNetworkBondLink = {
  link_name: string;
  link_uuid: string;
  link_speed: number;
  link_state: 'optimal' | 'degraded';
  is_active: boolean;
};

declare type AnvilNetworkNodeBond = {
  bond_name: string;
  bond_uuid: string;
  links: Array<AnvilNetworkBondLink>;
};

declare type AnvilNetworkNode = {
  host_name: string;
  host_uuid: string;
  bonds: Array<AnvilNetworkNodeBond>;
};

declare type AnvilNetwork = {
  nodes: Array<AnvilNetworkNode>;
};

declare type ProcessedBond = {
  bond_name: string;
  bond_uuid: string;
  nodes: Array<{
    host_name: string;
    host_uuid: string;
    link: {
      link_name: string;
      link_uuid: string;
      link_speed: number;
      link_state: 'optimal' | 'degraded';
      is_active: boolean;
    };
  }>;
};

declare type ProcessedNetwork = {
  bonds: Array<ProcessedBond>;
};
