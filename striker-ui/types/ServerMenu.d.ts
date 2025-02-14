type ServerOption = {
  disabled?: <Value extends ServerOption>(key: string, value: Value) => boolean;
  href?: <Value extends ServerOption>(key: string, value: Value) => string;
  onClick?: <Value extends ServerOption>(key: string, value: Value) => void;
  render: <Value extends ServerOption>(
    key: string,
    value: Value,
  ) => React.ReactNode;
};

type ServerMenuOptionalProps = {
  slotProps?: {
    button?: ButtonWithMenuProps<ServerOption>;
  };
};

type ServerMenuProps<
  Node extends NodeMinimum,
  Server extends ServerMinimum,
> = ServerMenuOptionalProps & {
  node: Node;
  server: Server;
};
