import { withStyles } from '@material-ui/core/styles';
import { LinearProgress } from '@material-ui/core';
import { PURPLE_OFF, RED_ON } from '../lib/consts/DEFAULT_THEME';

const BorderLinearProgress = withStyles({
  root: {
    height: 10,
    borderRadius: 5,
  },
  colorPrimary: {
    backgroundColor: PURPLE_OFF,
  },
  bar: {
    borderRadius: 5,
    backgroundColor: RED_ON,
  },
})(LinearProgress);

const AllocationBar = ({ allocated }: { allocated: number }): JSX.Element => {
  return (
    <>
      <BorderLinearProgress variant="determinate" value={allocated} />
      <LinearProgress variant="determinate" value={0} />
    </>
  );
};

export default AllocationBar;
