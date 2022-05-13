import { FC } from 'react';
import {
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
} from '@mui/material';

import {
  BLACK,
  BORDER_RADIUS,
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

        ...sx,
      },
    }}
  >
    {children}
  </MUIIconButton>
);

export default IconButton;
