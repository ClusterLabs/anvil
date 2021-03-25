declare type AnvilStatus = {
  anvil_state: 'optimal' | 'not_ready' | 'degraded';
  nodes: Array<{
    AnvilStatusNode;
  }>;
};
