import { Box, styled } from '@mui/material';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useContext, useEffect, useMemo } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import AnvilProvider, { AnvilContext } from '../../components/AnvilContext';
import Anvils from '../../components/Anvils';
import CPU from '../../components/CPU';
import Header from '../../components/Header';
import Hosts from '../../components/Hosts';
import Memory from '../../components/Memory';
import Network from '../../components/Network';
import { Panel } from '../../components/Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Servers from '../../components/Servers';
import SharedStorage from '../../components/SharedStorage';
import Spinner from '../../components/Spinner';
import useWindowDimensions from '../../hooks/useWindowDimenions';

const PREFIX = 'Anvil';

const classes = {
  child: `${PREFIX}-child`,
  server: `${PREFIX}-server`,
  container: `${PREFIX}-container`,
};

const StyledDiv = styled('div')(({ theme }) => ({
  [`& .${classes.child}`]: {
    width: '22%',
    height: '100%',
    [theme.breakpoints.down(LARGE_MOBILE_BREAKPOINT)]: {
      width: '50%',
    },
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },

  [`& .${classes.server}`]: {
    width: '35%',
    height: '100%',
    [theme.breakpoints.down('md')]: {
      width: '100%',
    },
  },

  [`& .${classes.container}`]: {
    display: 'flex',
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-between',
    [theme.breakpoints.down('md')]: {
      display: 'block',
    },
  },
}));

const Anvil = (): JSX.Element => {
  const router = useRouter();
  const width = useWindowDimensions();

  const { anvil_uuid: queryAnvilUUID } = router.query;
  const { uuid: contextAnvilUUID, setAnvilUuid } = useContext(AnvilContext);
  const { data, isLoading } = periodicFetch<AnvilList>(
    `${API_BASE_URL}/anvil/summary`,
  );

  const contentLayoutElement = useMemo(() => {
    let result;

    if (data && width) {
      result =
        width > LARGE_MOBILE_BREAKPOINT ? (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Anvils list={data} />
              <Hosts anvil={data.anvils} />
            </Box>
            <Box className={classes.server}>
              <Servers anvil={data.anvils} />
            </Box>
            <Box className={classes.child}>
              <SharedStorage />
            </Box>
            <Box className={classes.child}>
              <Network />
              <CPU />
              <Memory />
            </Box>
          </Box>
        ) : (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Servers anvil={data.anvils} />
              <Anvils list={data} />
              <Hosts anvil={data.anvils} />
            </Box>
            <Box className={classes.child}>
              <Network />
              <SharedStorage />
              <CPU />
              <Memory />
            </Box>
          </Box>
        );
    }

    return result;
  }, [data, width]);
  const contentAreaElement = useMemo(
    () =>
      isLoading ? (
        <Panel
          sx={{
            marginLeft: { xs: '1em', sm: 'auto' },
            marginRight: { xs: '1em', sm: 'auto' },
            marginTop: 'calc(50vh - 10em)',
            maxWidth: { xs: undefined, sm: '60%', md: '50%', lg: '40%' },
            minWidth: 'fit-content',
          }}
        >
          <Spinner sx={{ margin: '2em 2.4em' }} />
        </Panel>
      ) : (
        contentLayoutElement
      ),
    [contentLayoutElement, isLoading],
  );

  useEffect(() => {
    if (contextAnvilUUID === '') {
      setAnvilUuid(queryAnvilUUID?.toString() || '');
    }
  }, [contextAnvilUUID, queryAnvilUUID, setAnvilUuid]);

  return (
    <StyledDiv>
      <Head>
        <title>Anvil</title>
      </Head>
      <AnvilProvider>
        <Header />
        {contentAreaElement}
      </AnvilProvider>
    </StyledDiv>
  );
};

export default Anvil;
