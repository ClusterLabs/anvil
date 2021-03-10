import { Grid } from '@material-ui/core';
import Panel from './Panel';
import AllocationBar from './AllocationBar';
import { HeaderText, BodyText } from './Text';

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
          <AllocationBar allocated={50} />
        </Grid>
        <Grid item xs={5}>
          <BodyText text="Total Cores: 9" />
        </Grid>
        <Grid item xs={12}>
          <BodyText text="Threads: 16" />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default CPU;
