import { FC } from 'react';
import { Box } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const InnerPanelHeader: FC = ({ children }) => (
  <Box sx={{ position: 'relative', whiteSpace: 'pre-wrap' }}>
    <Box
      sx={{
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
    <Box sx={{ paddingBottom: '.4em', width: '100%', visibility: 'hidden' }}>
      {children instanceof Array ? children[0] : children}
    </Box>
  </Box>
);

export default InnerPanelHeader;
