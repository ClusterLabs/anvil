import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import Anvils from '../components/Anvils';
import Hosts from '../components/Hosts';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import Memory from '../components/Memory';
import Network from '../components/Network';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import Servers from '../components/Servers';
import Header from '../components/Header';
import AnvilProvider from '../components/AnvilContext';

const useStyles = makeStyles((theme) => ({
  child: {
    width: '22%',
    height: '100%',
    [theme.breakpoints.down('lg')]: {
      width: '25%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },
  server: {
    width: '35%',
    height: '100%',
    [theme.breakpoints.down('lg')]: {
      width: '25%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },
  container: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-between',
    [theme.breakpoints.down('md')]: {
      display: 'block',
    },
  },
}));

const Home = (): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilList>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_anvils`,
  );

  return (
    <>
      <AnvilProvider>
        <Header />
        {data?.anvils && (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Anvils list={data} />
              <Hosts anvil={data.anvils} />
            </Box>
            <Box className={classes.server}>
              <Servers anvil={data.anvils} />
            </Box>
            <Box className={classes.child}>
              <SharedStorage anvil={data.anvils} />
            </Box>
            <Box className={classes.child}>
              <Network />
              <CPU />
              <Memory />
            </Box>
          </Box>
        )}
      </AnvilProvider>
    </>
  );
};

export default Home;
