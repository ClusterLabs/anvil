import { useRouter } from 'next/router';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import CPU from '../../components/CPU';
import Memory from '../../components/Memory';
import Resource from '../../components/Resource';
import Display from '../../components/Display';
import Header from '../../components/Header';
import Domain from '../../components/Domain';

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

const Server = (): JSX.Element => {
  const classes = useStyles();

  const router = useRouter();
  const { uuid } = router.query;

  const { data } = PeriodicFetch<AnvilReplicatedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_replicated_storage?server_uuid=${uuid}`,
  );

  return (
    <>
      <Header />
      {typeof uuid === 'string' && data && (
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
            <Resource resource={data} />
          </Box>
        </Box>
      )}
    </>
  );
};

export default Server;
