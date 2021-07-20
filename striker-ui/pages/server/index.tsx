import { useState } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import { FullSize, Preview } from '../../components/Display';
import Header from '../../components/Header';

const useStyles = makeStyles((theme) => ({
  preview: {
    width: '20%',
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

const Server = (): JSX.Element => {
  const [previewMode, setPreviewMode] = useState<boolean>(true);
  const classes = useStyles();

  const router = useRouter();
  const { uuid, server_name } = router.query;

  return (
    <>
      <Head>
        <title>{server_name}</title>
      </Head>
      <Header />
      {typeof uuid === 'string' &&
        (previewMode ? (
          <Box className={classes.container}>
            <Box className={classes.preview}>
              <Preview setMode={setPreviewMode} serverName={server_name} />
            </Box>
          </Box>
        ) : (
          <Box className={classes.container}>
            <FullSize
              setMode={setPreviewMode}
              uuid={uuid}
              serverName={server_name}
            />
          </Box>
        ))}
    </>
  );
};

export default Server;
