import { FC } from 'react';
import {
  Box as MUIBox,
  Link as MUILink,
  LinkProps as MUILinkProps,
} from '@mui/material';
import { Link as LinkIcon } from '@mui/icons-material';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

export type LinkProps = MUILinkProps;

const Link: FC<LinkProps> = ({ children, sx, ...restLinkProps }) => (
  <MUILink
    {...{
      underline: 'hover',
      variant: 'subtitle1',
      ...restLinkProps,
      sx: {
        color: TEXT,
        textDecorationColor: GREY,

        ...sx,
      },
    }}
  >
    <MUIBox
      sx={{
        alignItems: 'center',
        display: 'flex',
        flexDirection: 'row',
      }}
    >
      {children}
      <LinkIcon sx={{ marginLeft: '.3em' }} />
    </MUIBox>
  </MUILink>
);

export default Link;
