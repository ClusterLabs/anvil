import { Grid } from '@material-ui/core';
import Panel from './Panel';
import AllocationBar from './AllocationBar';
import { HeaderText, BodyText } from './Text';

const Memory = (): JSX.Element => {
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Memory" />
        </Grid>
        <Grid item xs={3}>
          <BodyText text="Allocated: 14GiB" />
        </Grid>
        <Grid item xs={3}>
          <BodyText text="Free: 50GiB" />
        </Grid>
        <Grid item xs={10}>
          <AllocationBar allocated={30} />
        </Grid>
        <Grid item xs={6}>
          <BodyText text="Total Memory: 64GiB" />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Memory;
