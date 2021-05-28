const serverState: ReadonlyMap<string, string> = new Map([
  ['running', 'Running'],
  ['idle', 'Idle'],
  ['paused', 'Paused'],
  ['in shutdown', 'Shutting Down'],
  ['shut off', 'Off'],
  ['crashed', 'Crashed'],
  ['pmsuspended', 'PM Suspended'],
  ['migrating', 'Migrating'],
]);

export default serverState;
