import { FC } from 'react';
import {
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  inputClasses as muiInputClasses,
} from '@mui/material';

import {
  BLACK,
  BORDER_RADIUS,
  DISABLED,
  GREY,
  TEXT,
} from '../../lib/consts/DEFAULT_THEME';

export type IconButtonProps = MUIIconButtonProps;

const IconButton: FC<IconButtonProps> = ({
  children,
  sx,
  ...iconButtonRestProps
}) => (
  <MUIIconButton
    {...{
      ...iconButtonRestProps,
      sx: {
        borderRadius: BORDER_RADIUS,
        backgroundColor: GREY,
        color: BLACK,

        '&:hover': {
          backgroundColor: TEXT,
        },

        [`&.${muiInputClasses.disabled}`]: {
          backgroundColor: DISABLED,
        },

        ...sx,
      },
    }}
  >
    {children}
  </MUIIconButton>
);

export default IconButton;
