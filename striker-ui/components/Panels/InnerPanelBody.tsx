import { Box, BoxProps, SxProps, Theme } from '@mui/material';
import { FC, useMemo } from 'react';

const InnerPanelBody: FC<BoxProps> = ({ sx, ...innerPanelBodyRestProps }) => {
  const combinedSx = useMemo<SxProps<Theme>>(
    () => ({
      position: 'relative',
      zIndex: 20,

      ...sx,
    }),
    [sx],
  );

  return (
    <Box padding=".3em .7em" {...innerPanelBodyRestProps} sx={combinedSx} />
  );
};

export default InnerPanelBody;
