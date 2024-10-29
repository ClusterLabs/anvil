import { menuClasses, Menu as MuiMenu, styled } from '@mui/material';
import { FC, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import MenuItem from './MenuItem';

const BaseMenu = styled(MuiMenu)({
  [`& .${menuClasses.paper}`]: {
    backgroundColor: GREY,
  },
});

const Menu = <Item = unknown,>(
  ...[props]: Parameters<FC<MenuProps<Item>>>
): ReturnType<FC<MenuProps<Item>>> => {
  const {
    children,
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
    <BaseMenu open={open} {...menuProps}>
      {children || itemElements}
    </BaseMenu>
  );
};

export default Menu;
