import Typography from '@mui/material/Typography';
import { styled } from '@mui/material/styles';
import { TEXT } from '../../lib/consts/DEFAULT_THEME';

const WhiteTypography = styled(Typography)({
  color: TEXT,
});

const HeaderText = ({ text }: { text: string }): JSX.Element => (
  <WhiteTypography variant="h4">{text}</WhiteTypography>
);

export default HeaderText;
