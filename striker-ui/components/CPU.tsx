import { withStyles } from '@material-ui/core/styles';
import { Grid, LinearProgress } from '@material-ui/core';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';
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

const CPU = (): JSX.Element => {
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="CPU" />
        </Grid>
        <Grid item xs={3}>
          <BodyText text="Allocated: 3" />
        </Grid>
        <Grid item xs={3}>
          <BodyText text="Free: 6" />
        </Grid>
        <Grid item xs={10}>
          <BorderLinearProgress variant="determinate" value={50} />
          <LinearProgress variant="determinate" value={0} />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default CPU;
