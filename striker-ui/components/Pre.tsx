import { Box, BoxProps } from '@mui/material';
import { FC } from 'react';

import { TEXT } from '../lib/consts/DEFAULT_THEME';

const Pre: FC<BoxProps> = (props) => {
  const { children, ...restProps } = props;

  return (
    <Box
      color={TEXT}
      component="pre"
      whiteSpace="pre-wrap"
      width="100%"
      {...restProps}
    >
      {children}
    </Box>
  );
};

export default Pre;
