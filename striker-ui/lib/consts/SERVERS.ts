const serverState: ReadonlyMap<string, string> = new Map([
  ['running', 'Running'],
  ['idle', 'Idle'],
  ['paused', 'Paused'],
  ['in_shutdown', 'Shutting Down'],
  ['shut_off', 'Off'],
  ['crashed', 'crashed'],
  ['pmsuspended', 'Suspended'],
  ['migrating', 'Migrating'],
]);

export default serverState;
