import { Grid } from '@material-ui/core';
import Panel from './Panel';
import { HeaderText } from './Text';

const Network = (): JSX.Element => {
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Network" />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Network;
