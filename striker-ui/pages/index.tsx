import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import Header from '../components/Header';
import Anvils from '../components/Anvils';
import Nodes from '../components/Nodes';
import CPU from '../components/CPU';
import SharedStorage from '../components/SharedStorage';
import Memory from '../components/Memory';
import Network from '../components/Network';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import Servers from '../components/Servers';

import AnvilProvider from '../components/AnvilContext';

const useStyles = makeStyles(() => ({
  child: {
    width: '22%',
    height: '100%',
  },
  server: {
    width: '35%',
    height: '100%',
  },
}));

const Home = (): JSX.Element => {
  const classes = useStyles();

  const { data } = PeriodicFetch<AnvilList>(
    process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
    '/anvils/get_anvils',
  );

  return (
    <>
      <Header />
      <AnvilProvider>
        <Box
          display="flex"
          flexDirection="row"
          width="100%"
          justifyContent="space-between"
          alignContent="flex-start"
        >
          {data?.anvils && (
            <>
              <Box p={1} className={classes.child}>
                <Anvils list={data} />
                <Nodes anvil={data.anvils[0]} />
              </Box>
              <Box p={1} className={classes.server}>
                <Servers anvil={data.anvils} />
              </Box>
              <Box p={1} className={classes.child}>
                <SharedStorage anvil={data.anvils[0]} />
              </Box>
              <Box p={1} className={classes.child}>
                <Network anvil={data.anvils[0]} />
                <CPU uuid={data.anvils[0].anvil_uuid} />
                <Memory uuid={data.anvils[0].anvil_uuid} />
              </Box>
            </>
          )}
        </Box>
      </AnvilProvider>
    </>
  );
};

export default Home;
