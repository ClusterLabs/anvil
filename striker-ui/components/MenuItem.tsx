import {
  MenuItem as MUIMenuItem,
  menuItemClasses as muiMenuItemClasses,
  MenuItemProps as MUIMenuItemProps,
} from '@mui/material';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

const MenuItem = (menuItemProps: MUIMenuItemProps): JSX.Element => {
  const { children, sx } = menuItemProps;
  const combinedSx = {
    backgroundColor: TEXT,
    paddingRight: '3em',

    [`&.${muiMenuItemClasses.selected}`]: {
      backgroundColor: GREY,
      fontWeight: 400,

      [`&.${muiMenuItemClasses.focusVisible}`]: {
        backgroundColor: GREY,
      },

      '&:hover': {
        backgroundColor: GREY,
      },
    },

    [`&.${muiMenuItemClasses.focusVisible}`]: {
      backgroundColor: GREY,
    },

    '&:hover': {
      backgroundColor: GREY,
    },

    ...sx,
  };

  return (
    <MUIMenuItem
      {...{
        ...menuItemProps,
        sx: combinedSx,
      }}
    >
      {children}
    </MUIMenuItem>
  );
};

export default MenuItem;
