import { Grid } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import Anvils from '../components/Anvils';
import Nodes from '../components/Nodes';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import Memory from '../components/Memory';
import Network from '../components/Network';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import Servers from '../components/Servers';
import Storage from '../components/Storage';

const useStyles = makeStyles(() => ({
  grid: {
    height: '100vh',
  },
}));

const Home = (): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilList>(
    process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
    '/anvils/get_anvils',
  );

  return (
    <Grid container alignItems="center" justify="space-around">
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          // className={classes.grid}
        >
          <Anvils list={data} />
          <Nodes anvil={data?.anvils[0]} />
        </Grid>
      </Grid>
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          <Servers anvil={data?.anvils[0]} />
        </Grid>
      </Grid>
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          <Storage uuid={data?.anvils[0].anvil_uuid} />
          <SharedStorage anvil={data?.anvils[0]} />
        </Grid>
      </Grid>
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          {data?.anvils?.length ? (
            <>
              <Network />
              <CPU uuid={data.anvils[0].anvil_uuid} />
              <Memory uuid={data.anvils[0].anvil_uuid} />
            </>
          ) : null}
        </Grid>
      </Grid>
    </Grid>
  );
};

export default Home;
