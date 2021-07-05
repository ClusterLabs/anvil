import { useState } from 'react';
import { useRouter } from 'next/router';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import CPU from '../../components/CPU';
import Memory from '../../components/Memory';
import Resource from '../../components/Resource';
import { FullSize, Preview } from '../../components/Display';
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
  const [previewMode] = useState<boolean>(true);
  const classes = useStyles();

  const router = useRouter();
  const { uuid } = router.query;

  const { data } = PeriodicFetch<AnvilReplicatedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_replicated_storage?server_uuid=${uuid}`,
  );

  return (
    <>
      <Header />
      {typeof uuid === 'string' &&
        data &&
        (previewMode ? (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Preview />
              <CPU />
              <Memory />
            </Box>
            <Box flexGrow={1} className={classes.server}>
              <Domain />
            </Box>
            <Box className={classes.child}>
              <Resource resource={data} />
            </Box>
          </Box>
        ) : (
          <Box className={classes.container}>
            <FullSize />
          </Box>
        ))}
    </>
  );
};

export default Server;
