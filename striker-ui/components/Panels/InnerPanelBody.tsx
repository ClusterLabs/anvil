import { Box, BoxProps } from '@mui/material';
import { FC } from 'react';

const InnerPanelBody: FC<BoxProps> = ({ sx, ...innerPanelBodyRestProps }) => (
  <Box
    {...{
      ...innerPanelBodyRestProps,
      sx: {
        paddingLeft: '.7em',
        paddingRight: '.7em',
        paddingTop: '.3em',
        ...sx,
      },
    }}
  />
);

export default InnerPanelBody;
