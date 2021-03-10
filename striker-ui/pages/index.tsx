import { Grid } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import Anvils from '../components/Anvils';
import Nodes from '../components/Nodes';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import ReplicatedStorage from '../components/ReplicatedStorage';
import Memory from '../components/Memory';

import 'fontsource-roboto';

const useStyles = makeStyles(() => ({
  grid: {
    height: '100vh',
  },
}));

const Home = (): JSX.Element => {
  const classes = useStyles();

  return (
    <Grid container alignItems="center" justify="space-around">
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          <Anvils />
          <Nodes />
        </Grid>
      </Grid>
      <Grid item xs={5}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          <ReplicatedStorage />
        </Grid>
      </Grid>
      <Grid item xs={3}>
        <Grid
          container
          justify="flex-start"
          direction="column"
          className={classes.grid}
        >
          <SharedStorage />
          <CPU />
          <Memory />
        </Grid>
      </Grid>
    </Grid>
  );
};

export default Home;

/*
  return (
    <Grid container alignItems="center" justify="space-around">
      <Grid item xs={3}>
        <Grid container justify="flex-start" direction="column">
          <Anvils />
          <Nodes />
        </Grid>
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

    <>
      <div>
        <Grid container justify="flex-start" direction="column">
          <Anvils />
          <Nodes />
        </Grid>
      </div>
      <Grid container justify="flex-start" direction="column">
        <ReplicatedStorage />
      </Grid>
      <Grid container justify="flex-start" direction="column">
        <SharedStorage />
        <CPU />
        <Memory />
      </Grid>
    </>
  */
