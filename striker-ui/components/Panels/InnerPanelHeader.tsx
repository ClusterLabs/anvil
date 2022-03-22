import { ReactNode } from 'react';
import { Box, styled } from '@mui/material';

import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const PREFIX = 'InnerPanelHeader';

const classes = {
  header: `${PREFIX}-header`,
};

const StyledBox = styled(Box)(() => ({
  position: 'relative',
  padding: '0 .7em',
  whiteSpace: 'pre-wrap',

  [`& .${classes.header}`]: {
    top: '-.3em',
    left: '-.3em',
    padding: '1.4em 0',
    position: 'absolute',
    content: '""',
    borderColor: DIVIDER,
    borderWidth: '1px',
    borderRadius: BORDER_RADIUS,
    borderStyle: 'solid',
    width: '100%',
  },
}));

type Props = {
  children: ReactNode;
};

const InnerPanelHeader = ({ children }: Props): JSX.Element => (
  <StyledBox>
    <div className={classes.header} />
    {children}
  </StyledBox>
);

export default InnerPanelHeader;
