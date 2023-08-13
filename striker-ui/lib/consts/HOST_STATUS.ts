const SUBNODE_STATUS_MESSAGE_MAP: ReadonlyMap<string, string> = new Map([
  ['message_0222', 'The subnode is in an unknown state.'],
  ['message_0223', 'The subnode is a full cluster member.'],
  [
    'message_0224',
    'The subnode is coming online; the cluster resource manager is running (step 2/3).',
  ],
  [
    'message_0225',
    'The subnode is coming online; the subnode is a consensus cluster member (step 1/3).',
  ],
  [
    'message_0226',
    'The subnode has booted, but it is not (yet) joining the cluster.',
  ],
]);

export default SUBNODE_STATUS_MESSAGE_MAP;
