import { Box as MuiBox } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const InnerPanelHeader: React.FC<React.PropsWithChildren> = ({ children }) => (
  <MuiBox
    sx={{
      position: 'relative',
      whiteSpace: 'pre-wrap',
    }}
  >
    <MuiBox
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

        '& > :not(:first-child, :last-child)': {
          marginRight: '.3em',
        },
      }}
    >
      {children}
    </MuiBox>
    <MuiBox
      sx={{
        display: 'flex',
        paddingBottom: '.4em',
        paddingRight: '1.7em',
        visibility: 'hidden',
      }}
    >
      {children}
    </MuiBox>
  </MuiBox>
);

export default InnerPanelHeader;
