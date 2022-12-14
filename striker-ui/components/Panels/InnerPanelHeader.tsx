import { FC } from 'react';
import { Box } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const InnerPanelHeader: FC = ({ children }) => (
  <Box sx={{ position: 'relative', whiteSpace: 'pre-wrap' }}>
    <Box
      sx={{
        alignItems: 'center',
        borderColor: DIVIDER,
        borderRadius: BORDER_RADIUS,
        borderStyle: 'solid',
        borderWidth: '1px',
        display: 'flex',
        left: '-.3em',
        paddingBottom: '.2em',
        paddingLeft: '1em',
        paddingRight: '.7em',
        paddingTop: '.4em',
        position: 'absolute',
        top: '-.3em',
        width: '100%',
        zIndex: '10',

        '& > :first-child': {
          flexGrow: 1,
        },
      }}
    >
      {children}
    </Box>
    <Box
      sx={{
        display: 'flex',
        paddingBottom: '.4em',
        paddingRight: '1.7em',
        visibility: 'hidden',
      }}
    >
      {children}
    </Box>
  </Box>
);

export default InnerPanelHeader;
