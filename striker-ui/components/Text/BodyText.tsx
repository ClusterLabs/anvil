import { Typography } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';
import { TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

interface TextProps {
  text: string;
  selected?: boolean;
}

const useStyles = makeStyles(() => ({
  selected: {
    color: TEXT,
  },
  unselected: {
    color: UNSELECTED,
  },
}));

const BodyText = ({ text, selected }: TextProps): JSX.Element => {
  const classes = useStyles();

  return (
    <Typography
      variant="subtitle1"
      className={selected ? classes.selected : classes.unselected}
    >
      {text}
    </Typography>
  );
};

BodyText.defaultProps = {
  selected: true,
};

export default BodyText;
