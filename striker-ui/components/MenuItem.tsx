import {
  MenuItem as MuiMenuItem,
  menuItemClasses as muiMenuItemClasses,
  styled,
} from '@mui/material';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

const MenuItem = styled(MuiMenuItem)({
  backgroundColor: GREY,
  paddingRight: '3em',

  [`&.${muiMenuItemClasses.selected}`]: {
    backgroundColor: TEXT,
    fontWeight: 400,

    [`&.${muiMenuItemClasses.focusVisible}`]: {
      backgroundColor: TEXT,
    },

    '&:hover': {
      backgroundColor: TEXT,
    },
  },

  [`&.${muiMenuItemClasses.focusVisible}`]: {
    backgroundColor: TEXT,
  },

  '&:hover': {
    backgroundColor: TEXT,
  },
});

export default MenuItem;
