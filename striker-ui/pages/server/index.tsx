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

  return (
    <StyledDiv>
      <Head>
        <title>{server_name}</title>
      </Head>
      <Header />
      {typeof uuid === 'string' &&
        (previewMode ? (
          <Box className={classes.preview}>
            <Preview
              setMode={setPreviewMode}
              serverName={server_name}
              serverUUID={uuid}
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
    </StyledDiv>
  );
};

export default Server;
