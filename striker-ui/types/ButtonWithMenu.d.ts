type ButtonWithMenuOptionalProps<T = unknown> = Omit<MenuProps<T>, 'open'> & {
  onButtonClick?: import('react').MouseEventHandler<HTMLButtonElement>;
  variant?: 'contained' | 'icon';
};

type ButtonWithMenuProps<T = unknown> = ButtonWithMenuOptionalProps<T>;
