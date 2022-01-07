import { ReactNode } from 'react';
import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';
import { BORDER_RADIUS, DIVIDER } from '../../lib/consts/DEFAULT_THEME';

const StyledBox = styled(Box)({
  borderWidth: '1px',
  borderRadius: BORDER_RADIUS,
  borderStyle: 'solid',
  borderColor: DIVIDER,
  marginTop: '1.4em',
  marginBottom: '1.4em',
  paddingBottom: 0,
  position: 'relative',
});

type Props = {
  children: ReactNode;
};

const InnerPanel = ({ children }: Props): JSX.Element => {
  return <StyledBox>{children}</StyledBox>;
};

export default InnerPanel;
