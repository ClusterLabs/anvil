import { Box, styled } from '@mui/material';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useContext, useEffect, useMemo } from 'react';

import { LARGE_MOBILE_BREAKPOINT } from '../../lib/consts/DEFAULT_THEME';

import AnvilProvider, { AnvilContext } from '../../components/AnvilContext';
import Anvils from '../../components/Anvils';
import CPU from '../../components/CPU';
import Header from '../../components/Header';
import Hosts from '../../components/Hosts';
import Memory from '../../components/Memory';
import Network from '../../components/Network';
import { Panel } from '../../components/Panels';
import Servers from '../../components/Servers';
import SharedStorage from '../../components/SharedStorage';
import Spinner from '../../components/Spinner';
import useWindowDimensions from '../../hooks/useWindowDimenions';
import useFetch from '../../hooks/useFetch';

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

  const { setAnvilUuid } = useContext(AnvilContext);

  const { data: summary, loading: loadingSummary } = useFetch<AnvilList>(
    `/anvil/summary`,
    {
      periodic: true,
    },
  );

  const contentLayoutElement = useMemo(() => {
    let result;

    if (summary && width) {
      result =
        width > LARGE_MOBILE_BREAKPOINT ? (
          <Box className={classes.container}>
            <Box className={classes.child}>
              <Anvils list={summary} />
              <Hosts anvil={summary.anvils} />
            </Box>
            <Box className={classes.server}>
              <Servers anvil={summary.anvils} />
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
              <Servers anvil={summary.anvils} />
              <Anvils list={summary} />
              <Hosts anvil={summary.anvils} />
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
  }, [summary, width]);

  const contentAreaElement = useMemo(
    () =>
      loadingSummary ? (
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
    [contentLayoutElement, loadingSummary],
  );

  useEffect(() => {
    if (!router.isReady || !summary) {
      return;
    }

    const { anvils } = summary;

    const { name, uuid } = router.query;

    let anvil: AnvilListItem | undefined;

    if (name) {
      anvil = anvils.find((li) => li.anvil_name === name);
    } else if (uuid) {
      anvil = anvils.find((li) => li.anvil_uuid === uuid);
    }

    if (!anvil) {
      return;
    }

    const { anvil_uuid: anvilUuid } = anvil;

    setAnvilUuid(anvilUuid);
  }, [router.isReady, router.query, setAnvilUuid, summary]);

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
