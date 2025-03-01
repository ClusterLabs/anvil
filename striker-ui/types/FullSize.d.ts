type FullSizeOptionalProps = {
  onClickCloseButton?: import('@mui/material').IconButtonProps['onClick'];
  vncReconnectTimerStart?: number;
};

type FullSizeProps<
  Node extends NodeMinimum,
  Server extends ServerMinimum,
> = FullSizeOptionalProps & {
  node: Node;
  server: Server;
};

type FullSizeComponent<
  Node extends NodeMinimum,
  Server extends ServerMinimum,
> = React.FC<FullSizeProps<Node, Server>>;
