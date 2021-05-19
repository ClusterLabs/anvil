import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import CPU from '../components/CPU';
import Memory from '../components/Memory';
import Resource from '../components/Resource';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import Display from '../components/Display';
import Header from '../components/Header';
import Domain from '../components/Domain';

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
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_anvils`,
  );

  return (
    <>
      <Header />
      {data?.anvils && (
        <Box className={classes.container}>
          <Box className={classes.child}>
            <CPU />
            <Memory />
          </Box>
          <Box flexGrow={1} className={classes.server}>
            <Display />
            <Domain />
          </Box>
          <Box className={classes.child}>
            <Resource />
          </Box>
        </Box>
      )}
    </>
  );
};

export default Home;
