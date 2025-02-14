type ButtonWithMenuOptionalProps<T = unknown> = Pick<
  MenuProps<T>,
  'getItemDisabled' | 'getItemHref' | 'items' | 'onItemClick' | 'renderItem'
> & {
  onClick?: import('react').MouseEventHandler<HTMLButtonElement>;
  slotProps?: {
    button?: {
      contained?: Partial<ContainedButtonProps>;
      icon?: Partial<import('../components/IconButton').IconButtonProps>;
    };
    menu?: Partial<MenuProps<T>>;
  };
  variant?: 'contained' | 'icon';
};

type ButtonWithMenuProps<T = unknown> = ButtonWithMenuOptionalProps<T>;
