declare type AnvilStatusHost = {
  state: 'offline' | 'booted' | 'crmd' | 'in_ccm' | 'online';
  host_uuid: string;
  host_name: string;
  state_percent: number;
  state_message: string;
  removable: boolean;
};

declare type AnvilStatus = {
  anvil_state: 'optimal' | 'not_ready' | 'degraded';
  hosts: Array<AnvilStatusHost>;
};
