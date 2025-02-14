import {
  menuClasses as muiMenuClasses,
  MenuItemProps as MuiMenuItemProps,
  Menu as MuiMenu,
  styled,
} from '@mui/material';
import { useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import MenuItem from './MenuItem';

const BaseMenu = styled(MuiMenu)({
  [`& .${muiMenuClasses.paper}`]: {
    backgroundColor: GREY,
  },
});

const Menu = <Item = unknown,>(
  ...[props]: Parameters<React.FC<MenuProps<Item>>>
): ReturnType<React.FC<MenuProps<Item>>> => {
  const {
    children,
    getItemDisabled,
    getItemHref,
    items = {},
    onItemClick,
    open,
    renderItem,
    slotProps,
  } = props;

  const pairs = useMemo(() => Object.entries(items), [items]);

  const itemElements = useMemo(
    () =>
      pairs.map(([key, value]) => {
        const itemProps: Pick<
          MuiMenuItemProps,
          'component' | 'disabled' | 'onClick'
        > & {
          href?: string;
        } = {
          disabled: getItemDisabled?.call(null, key, value),
        };

        const href = getItemHref?.call(null, key, value);

        if (href) {
          itemProps.component = 'a';
          itemProps.href = href;
        } else {
          itemProps.onClick = (...args) =>
            onItemClick?.call(null, key, value, ...args);
        }

        return (
          <MenuItem
            // The key is only relevant within the same branch; i.e., instance of
            // the same key under a different parent is OK.
            key={key}
            {...itemProps}
            {...slotProps?.item}
          >
            {renderItem?.call(null, key, value)}
          </MenuItem>
        );
      }),
    [
      getItemDisabled,
      getItemHref,
      onItemClick,
      pairs,
      renderItem,
      slotProps?.item,
    ],
  );

  return (
    <BaseMenu open={open} {...slotProps?.menu}>
      {children || itemElements}
    </BaseMenu>
  );
};

export default Menu;
