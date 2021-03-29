import { Grid } from '@material-ui/core';
import Anvil from './Anvil';
import Panel from './Panel';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const Anvils = ({ list }: { list: AnvilList | undefined }): JSX.Element => {
  const anvils: AnvilListItem[] = [];

  list?.anvils.forEach((anvil: AnvilListItem) => {
    const { data } = PeriodicFetch<AnvilStatus>(
      `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=`,
      anvil.anvil_uuid,
    );
    /* eslint-disable no-param-reassign */
    anvils.push({
      ...anvil,
      anvil_state: data?.anvil_state,
    });
  });

  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        {anvils.map((anvil) => (
          <Anvil anvil={anvil} key={anvil.anvil_uuid} />
        ))}
      </Grid>
    </Panel>
  );
};

export default Anvils;
