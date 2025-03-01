type MuiMenuProps = import('@mui/material').MenuProps;

type MenuOptionalProps<T = unknown> = Pick<MuiMenuProps, 'open'> & {
  getItemDisabled?: (key: string, value: T) => boolean | undefined;
  getItemHref?: (key: string, value: T) => string | undefined;
  items?: Record<string, T>;
  onItemClick?: (
    key: string,
    value: T,
    ...parent: Parameters<MuiMenuItemClickEventHandler>
  ) => ReturnType<MuiMenuItemClickEventHandler>;
  renderItem?: (key: string, value: T) => import('react').ReactNode;
  slotProps?: {
    item?: Partial<MuiMenuItemProps>;
    menu?: Partial<MuiMenuProps>;
  };
};

type MenuProps<T = unknown> = MenuOptionalProps<T>;
