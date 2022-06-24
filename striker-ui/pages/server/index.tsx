import { useState } from 'react';
import { useRouter } from 'next/router';
import Head from 'next/head';
import { Box } from '@mui/material';
import { styled } from '@mui/material/styles';

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
  const { uuid, server_name } = router.query;
  const serverUUID: string = uuid?.toString() || '';
  const serverName: string = server_name?.toString() || '';

  return (
    <StyledDiv>
      <Head>
        <title>{serverName}</title>
      </Head>
      <Header />
      {previewMode ? (
        <Box className={classes.preview}>
          <Preview
            setMode={setPreviewMode}
            serverName={serverName}
            serverUUID={serverUUID}
          />
        </Box>
      ) : (
        <Box className={classes.fullView}>
          <FullSize
            setMode={setPreviewMode}
            serverUUID={serverUUID}
            serverName={serverName}
          />
        </Box>
      )}
    </StyledDiv>
  );
};

export default Server;
