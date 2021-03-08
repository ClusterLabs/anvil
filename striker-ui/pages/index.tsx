import { GetServerSidePropsResult } from 'next';
import { Grid } from '@material-ui/core';

import Anvils from '../components/Anvils';
import Nodes from '../components/Nodes';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import ReplicatedStorage from '../components/ReplicatedStorage';
import State from '../components/State';
import Memory from '../components/Memory';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import fetchJSON from '../lib/fetchers/fetchJSON';

import 'typeface-muli';

export async function getServerSideProps(): Promise<
  GetServerSidePropsResult<AnvilList>
> {
  return {
    props: await fetchJSON(`${API_BASE_URL}/api/anvils`),
  };
}

const Home = (): JSX.Element => {
  return (
    <Grid container alignItems="center" justify="space-around">
      <Grid item xs={3}>
        <Anvils />
        <State />
        <Nodes />
      </Grid>
      <Grid item xs={5}>
        <ReplicatedStorage />
      </Grid>
      <Grid item xs={3}>
        <CPU />
        <SharedStorage />
        <Memory />
      </Grid>
    </Grid>
  );
};

export default Home;
