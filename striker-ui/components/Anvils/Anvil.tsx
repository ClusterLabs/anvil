import { Grid } from '@material-ui/core';
import { BodyText } from '../Text';

const Anvil = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  return (
    <Grid item xs={12}>
      <BodyText text={anvil.anvil_name} />
      <BodyText text={anvil.anvil_state || 'State unavailable'} />
    </Grid>
  );
};

export default Anvil;
