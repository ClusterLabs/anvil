import { Grid } from '@material-ui/core';

import Anvils from '../components/Anvils';
import Nodes from '../components/Nodes';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import ReplicatedStorage from '../components/ReplicatedStorage';
import Memory from '../components/Memory';

import 'fontsource-roboto';

const Home = (): JSX.Element => {
  return (
    <Grid container alignItems="center" justify="space-around">
      <Grid item xs={3}>
        <Anvils />
        <Nodes />
      </Grid>
      <Grid item xs={5}>
        <ReplicatedStorage />
      </Grid>
      <Grid item xs={3}>
        <SharedStorage />
        <CPU />
        <Memory />
      </Grid>
    </Grid>
  );
};

export default Home;
