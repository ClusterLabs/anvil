declare type AnvilNetworkBondLink = {
  link_name: string;
  link_uuid: string;
  link_speed: number;
  link_state: 'optimal' | 'degraded' | 'down';
  is_active: boolean;
};

declare type AnvilNetworkHostBond = {
  bond_name: string;
  bond_uuid: string;
  links: Array<AnvilNetworkBondLink>;
};

declare type AnvilNetworkHosts = {
  host_name: string;
  host_uuid: string;
  bonds: Array<AnvilNetworkHostBond>;
};

declare type AnvilNetwork = {
  hosts: Array<AnvilNetworkHosts>;
};

declare type ProcessedBond = {
  bond_name: string;
  bond_uuid: string;
  bond_speed: number;
  bond_state: 'optimal' | 'degraded' | 'down';
  hosts: Array<{
    host_name: string;
    host_uuid: string;
    link: {
      link_name: string;
      link_uuid: string;
      link_speed: number;
      link_state: 'optimal' | 'degraded' | 'down';
      is_active: boolean;
    };
  }>;
};

declare type ProcessedNetwork = {
  bonds: Array<ProcessedBond>;
};
