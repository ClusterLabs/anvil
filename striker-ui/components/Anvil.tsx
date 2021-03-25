import { useState } from 'react';
import { Switch, Grid } from '@material-ui/core';
import { HeaderText } from './Text';

const Anvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const [checked, setChecked] = useState<boolean>(true);
  return (
    <>
      <Grid item xs={6}>
        <HeaderText text={anvil.anvil_name} />
        <HeaderText
          text={anvil.anvil_status?.anvil_state || 'State unavailable'}
        />
      </Grid>
      <Grid item xs={3}>
        <Switch checked={checked} onChange={() => setChecked(!checked)} />
      </Grid>
    </>
  );
};

export default Anvil;
