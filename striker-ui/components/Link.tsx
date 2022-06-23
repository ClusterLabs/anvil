import { FC } from 'react';
import { Link as MUILink, LinkProps as MUILinkProps } from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

export type LinkProps = MUILinkProps;

const Link: FC<LinkProps> = ({ children, sx, ...restLinkProps }) => (
  <MUILink
    {...{
      underline: 'always',
      variant: 'subtitle1',
      ...restLinkProps,
      sx: {
        color: GREY,
        textDecorationColor: GREY,
        ...sx,
      },
    }}
  >
    {children}
  </MUILink>
);

export default Link;
