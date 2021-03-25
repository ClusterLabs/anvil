declare type AnvilStatusNode = {
  state: 'unknown' | 'off' | 'on' | 'accessible' | 'ready';
  state_percent: number;
  state_message: string;
};
