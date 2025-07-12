const statesMap: ReadonlyMap<string, string> = new Map([
  ['running', 'Running'],
  ['idle', 'Idle'],
  ['paused', 'Paused'],
  ['in shutdown', 'Shutting Down'],
  ['shut off', 'Off'],
  ['crashed', 'Crashed'],
  ['pmsuspended', 'PM Suspended'],
  ['migrating', 'Migrating'],
  ['provisioning', 'Provisioning'],
]);

const blockingStates: ServerState[] = [
  'deleting',
  'in bootup',
  'in shutdown',
  'provisioning',
  'renaming',
];

const SERVER = {
  states: {
    blocking: blockingStates,
    map: statesMap,
  },
};

export default SERVER;
