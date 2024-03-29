const NETWORK_TYPES: Record<NetworkType, string> & Record<string, string> = {
  bcn: 'Back-Channel Network',
  ifn: 'Internet-Facing Network',
  mn: 'Migration Network',
  sn: 'Storage Network',
};

export default NETWORK_TYPES;
