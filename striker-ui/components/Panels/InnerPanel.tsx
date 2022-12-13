import { FC } from 'react';
import { Box as MUIBox, BoxProps as MUIBoxProps } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

type InnerPanelProps = MUIBoxProps;

const InnerPanel: FC<InnerPanelProps> = ({ sx, ...muiBoxRestProps }) => (
  <MUIBox
    {...{
      sx: {
        borderWidth: '1px',
        borderRadius: BORDER_RADIUS,
        borderStyle: 'solid',
        borderColor: DIVIDER,
        marginTop: '1.4em',
        marginBottom: '1.4em',
        paddingBottom: 0,
        position: 'relative',

        ...sx,
      },
      ...muiBoxRestProps,
    }}
  />
);

export default InnerPanel;
