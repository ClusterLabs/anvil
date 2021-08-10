import { useState } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import { Box } from '@material-ui/core';
import { makeStyles } from '@material-ui/core/styles';

import { FullSize, Preview } from '../../components/Display';
import Header from '../../components/Header';

const useStyles = makeStyles((theme) => ({
  preview: {
    width: '25%',
    height: '100%',
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },
  fullView: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'center',
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
          <Box className={classes.preview}>
            <Preview
              setMode={setPreviewMode}
              uuid={uuid}
              serverName={server_name}
            />
          </Box>
        ) : (
          <Box className={classes.fullView}>
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
