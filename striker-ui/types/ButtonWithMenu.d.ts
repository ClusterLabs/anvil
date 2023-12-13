type ButtonWithMenuOptionalProps<T = unknown> = Omit<MenuProps<T>, 'open'> & {
  containedButtonProps?: Partial<ContainedButtonProps>;
  iconButtonProps?: Partial<import('../components/IconButton').IconButtonProps>;
  onButtonClick?: import('react').MouseEventHandler<HTMLButtonElement>;
  variant?: 'contained' | 'icon';
};

type ButtonWithMenuProps<T = unknown> = ButtonWithMenuOptionalProps<T>;
