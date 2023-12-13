type MuiMenuProps = import('@mui/material').MenuProps;

type MenuOptionalProps<T = unknown> = Pick<MuiMenuProps, 'open'> & {
  getItemDisabled?: (key: string, value: T) => boolean;
  items?: Record<string, T>;
  muiMenuProps?: Partial<MuiMenuProps>;
  onItemClick?: (
    key: string,
    value: T,
    ...parent: Parameters<MuiMenuItemClickEventHandler>
  ) => ReturnType<MuiMenuItemClickEventHandler>;
  renderItem?: (key: string, value: T) => import('react').ReactNode;
};

type MenuProps<T = unknown> = MenuOptionalProps<T>;
