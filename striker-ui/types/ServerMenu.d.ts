type ServerPowerOption = {
  description: import('react').ReactNode;
  label: string;
  path: string;
  colour?: Exclude<ContainedButtonBackground, 'normal'>;
};

type MapToServerPowerOption = Record<string, ServerPowerOption>;

type ServerMenuProps = ButtonWithMenuProps & {
  serverName: string;
  serverState: string;
  serverUuid: string;
};
