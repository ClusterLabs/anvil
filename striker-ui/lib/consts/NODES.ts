const NODE_STATUS_MESSAGE_MAP: ReadonlyMap<string, string> = new Map([
  ['message_0222', 'The node is in an unknown state.'],
  ['message_0223', 'The node is a full cluster member.'],
  [
    'message_0224',
    'The node is coming online; the cluster resource manager is running (step 2/3).',
  ],
  [
    'message_0225',
    'The node is coming online; the node is a consensus cluster member (step 1/3).',
  ],
  [
    'message_0226',
    'The node has booted, but it is not (yet) joining the cluster.',
  ],
]);

export default NODE_STATUS_MESSAGE_MAP;
