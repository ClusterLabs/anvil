import { Menu as MuiMenu } from '@mui/material';
import { FC, useMemo } from 'react';

import MenuItem from './MenuItem';

const Menu: FC<MenuProps> = (props) => {
  const {
    getItemDisabled,
    items = {},
    muiMenuProps: menuProps,
    onItemClick,
    open,
    renderItem,
  } = props;

  const pairs = useMemo(() => Object.entries(items), [items]);

  const itemElements = useMemo(
    () =>
      pairs.map(([key, value]) => (
        <MenuItem
          disabled={getItemDisabled?.call(null, key, value)}
          onClick={(...parent) =>
            onItemClick?.call(null, key, value, ...parent)
          }
          // The key is only relevant within the same branch; i.e., instance of
          // the same key under a different parent is OK.
          key={key}
        >
          {renderItem?.call(null, key, value)}
        </MenuItem>
      )),
    [getItemDisabled, onItemClick, pairs, renderItem],
  );

  return (
    <MuiMenu open={open} {...menuProps}>
      {itemElements}
    </MuiMenu>
  );
};

export default Menu as <T>(props: MenuProps<T>) => ReturnType<FC<MenuProps<T>>>;
