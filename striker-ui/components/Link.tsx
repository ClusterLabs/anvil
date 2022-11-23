import { Link as MUILinkIcon } from '@mui/icons-material';
import { Link as MUILink } from '@mui/material';
import { FC } from 'react';

import { GREY, TEXT } from '../lib/consts/DEFAULT_THEME';

import FlexBox from './FlexBox';

const Link: FC<LinkProps> = ({ children, sx: linkSx, ...restLinkProps }) => (
  <MUILink
    underline="hover"
    variant="subtitle1"
    {...restLinkProps}
    sx={{
      color: TEXT,
      textDecorationColor: GREY,
      ...linkSx,
    }}
  >
    <FlexBox row>
      {children}
      <MUILinkIcon sx={{ marginLeft: '.3em' }} />
    </FlexBox>
  </MUILink>
);

export default Link;
