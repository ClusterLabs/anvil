import { Box, BoxProps } from '@mui/material';
import { FC } from 'react';

const InnerPanelBody: FC<BoxProps> = ({ sx, ...innerPanelBodyRestProps }) => (
  <Box
    {...{
      ...innerPanelBodyRestProps,
      sx: {
        padding: '.3em .7em',

        ...sx,
      },
    }}
  />
);

export default InnerPanelBody;
