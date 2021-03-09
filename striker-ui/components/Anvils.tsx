import { useState } from 'react';
import { Switch, Grid } from '@material-ui/core';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';

const Anvils = (): JSX.Element => {
  const [checked, setChecked] = useState<boolean>(true);
  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Anvils" />
        </Grid>
        <Grid item xs={4}>
          <BodyText text="Anvil 4" />
          <BodyText text="Optimal" />
        </Grid>
        <Grid item xs={3}>
          <Switch checked={checked} onChange={() => setChecked(!checked)} />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default Anvils;
