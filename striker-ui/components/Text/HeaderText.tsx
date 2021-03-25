import { Typography } from '@material-ui/core';
import { withStyles } from '@material-ui/core/styles';
import { TEXT } from '../../lib/consts/DEFAULT_THEME';

const WhiteTypography = withStyles({
  root: {
    color: TEXT,
  },
})(Typography);

const HeaderText = ({ text }: { text: string }): JSX.Element => {
  return <WhiteTypography variant="h5">{text}</WhiteTypography>;
};

export default HeaderText;
