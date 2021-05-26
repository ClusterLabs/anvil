declare type AnvilStatusNode = {
  state: 'unknown' | 'off' | 'on' | 'accessible' | 'ready';
  host_uuid: string;
  host_name: string;
  state_percent: number;
  state_message: string;
  removable: boolean;
};

declare type AnvilStatus = {
  anvil_state: 'optimal' | 'not_ready' | 'degraded';
  nodes: Array<AnvilStatusNode>;
};
