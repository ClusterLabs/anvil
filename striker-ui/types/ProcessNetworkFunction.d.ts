type ProcessedBond = {
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

type ProcessedNetwork = {
  bonds: ProcessedBond[];
};
