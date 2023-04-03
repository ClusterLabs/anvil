import { FC, useMemo } from 'react';
import { Box as MUIBox, SxProps, Theme } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const InnerPanel: FC<InnerPanelProps> = ({ sx, ...muiBoxRestProps }) => {
  const combinedSx = useMemo<SxProps<Theme>>(
    () => ({
      borderWidth: '1px',
      borderRadius: BORDER_RADIUS,
      borderStyle: 'solid',
      borderColor: DIVIDER,
      marginTop: '1.4em',
      marginBottom: '1.4em',
      paddingBottom: 0,
      position: 'relative',

      ...sx,
    }),
    [sx],
  );

  return <MUIBox {...muiBoxRestProps} sx={combinedSx} />;
};

export default InnerPanel;
