import { withStyles } from '@material-ui/core/styles';
import { Grid, LinearProgress, Typography } from '@material-ui/core';
import Panel from './Panel';
import Text from './Text/HeaderText';
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

const Memory = (): JSX.Element => {
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <Text text="Memory" />
        </Grid>
        <Grid item xs={3}>
          <Typography variant="subtitle1">Allocated: 14GB</Typography>
        </Grid>
        <Grid item xs={3}>
          <Typography variant="subtitle1">Free: 50GB</Typography>
        </Grid>
        <Grid item xs={10}>
          <BorderLinearProgress variant="determinate" value={50} />
          <LinearProgress variant="determinate" value={0} />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Memory;
