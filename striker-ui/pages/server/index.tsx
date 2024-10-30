import { Box, styled } from '@mui/material';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useEffect, useState } from 'react';

import { FullSize } from '../../components/Display';
import Header from '../../components/Header';
import { ManageServer } from '../../components/ManageServer';
import PageBody from '../../components/PageBody';

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

  const { server_name = '', uuid = '', vnc = '' } = router.query;

  const isConnectVnc: boolean = Boolean(vnc);
  const serverName: string = String(server_name);
  const serverUuid: string = String(uuid);

  useEffect(() => {
    if (isConnectVnc) {
      setPreviewMode(false);
    }
  }, [isConnectVnc]);

  return (
    <StyledDiv>
      <Head>
        <title>{serverName}</title>
      </Head>
      <Header />
      {previewMode ? (
        <PageBody>
          <ManageServer
            slotProps={{
              preview: {
                onClick: () => {
                  setPreviewMode(false);
                },
              },
            }}
            serverUuid={serverUuid}
          />
        </PageBody>
      ) : (
        <Box className={classes.fullView}>
          <FullSize
            onClickCloseButton={() => {
              setPreviewMode(true);
            }}
            serverUUID={serverUuid}
            serverName={serverName}
          />
        </Box>
      )}
    </StyledDiv>
  );
};

export default Server;
