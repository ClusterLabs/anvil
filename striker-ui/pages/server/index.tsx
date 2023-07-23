import { Box, styled } from '@mui/material';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

import { FullSize, Preview } from '../../components/Display';
import Header from '../../components/Header';

const PREFIX = 'Server';

const classes = {
  preview: `${PREFIX}-preview`,
  fullView: `${PREFIX}-fullView`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.preview}`]: {
    width: '25%',
    height: '100%',
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },

  [`& .${classes.fullView}`]: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'center',
  },
}));

const Server = (): JSX.Element => {
  const [previewMode, setPreviewMode] = useState<boolean>(true);

  const router = useRouter();
  const { server_name, uuid, vnc } = router.query;
  const isConnectVNC: boolean = (vnc?.toString() || '').length > 0;
  const serverUUID: string = uuid?.toString() || '';
  const serverName: string = server_name?.toString() || '';

  useEffect(() => {
    if (isConnectVNC) {
      setPreviewMode(false);
    }
  }, [isConnectVNC]);

  return (
    <StyledDiv>
      <Head>
        <title>{serverName}</title>
      </Head>
      <Header />
      {previewMode ? (
        <Box className={classes.preview}>
          <Preview
            onClickPreview={() => {
              setPreviewMode(false);
            }}
            serverName={serverName}
            serverUUID={serverUUID}
          />
        </Box>
      ) : (
        <Box className={classes.fullView}>
          <FullSize
            onClickCloseButton={() => {
              setPreviewMode(true);
            }}
            serverUUID={serverUUID}
            serverName={serverName}
          />
        </Box>
      )}
    </StyledDiv>
  );
};

export default Server;
