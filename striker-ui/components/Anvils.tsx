import { useState } from 'react';
import { Switch, Grid } from '@material-ui/core';
import Panel from './Panel';
import { HeaderText, BodyText } from './Text';

const Anvils = ({ list }: { list: AnvilList | undefined }): JSX.Element => {
  const [checked, setChecked] = useState<boolean>(true);
  let anvils: AnvilListItem[] = [];
  if (list) anvils = list.anvils;

  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="Anvils" />
        </Grid>
        <Grid item xs={4}>
          <BodyText
            text={anvils.length > 0 ? anvils[0].anvil_name : 'Anvil 1'}
          />
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
