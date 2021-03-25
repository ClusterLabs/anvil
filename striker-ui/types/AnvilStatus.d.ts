declare type AnvilStatus = {
  anvil_state: 'optimal' | 'not_ready' | 'degraded';
  nodes: Array<{
    state: 'unknown' | 'off' | 'on' | 'accessible' | 'ready';
    state_percent: number;
    state_message: string;
  }>;
};
