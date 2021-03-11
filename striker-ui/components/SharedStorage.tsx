import { Grid } from '@material-ui/core';
import InnerPanel from './InnerPanel';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';

const SharedStorage = (): JSX.Element => {
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Shared Storage" />
        </Grid>
        <Grid item xs={12}>
          <BodyText text="Mount /mnt/shared" />
        </Grid>
        <Grid item xs={12}>
          <InnerPanel />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default SharedStorage;
