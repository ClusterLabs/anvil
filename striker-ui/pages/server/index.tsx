import MuiBox from '@mui/material/Box';
import styled from '@mui/material/styles/styled';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useMemo } from 'react';

import { FullSize } from '../../components/Display';
import getListValueFromRouterQuery from '../../lib/getListValueFromRouterQuery';
import getQueryParam from '../../lib/getQueryParam';
import Header from '../../components/Header';
import { ManageServer } from '../../components/ManageServer';
import MessageBox from '../../components/MessageBox';
import PageBody from '../../components/PageBody';
import { Panel } from '../../components/Panels';
import setQueryParam from '../../lib/setQueryParam';
import Spinner from '../../components/Spinner';
import useFetch from '../../hooks/useFetch';

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

const Server = (): React.ReactElement => {
  const router = useRouter();

  const {
    data: servers,
    error: fetchError,
    loading: loadingServers,
  } = useFetch<APIServerOverviewList>('/server');

  const server = useMemo(
    () =>
      getListValueFromRouterQuery(
        servers,
        router,
        (name) => (value) => value.name === name,
      ),
    [router, servers],
  );

  const view = useMemo<string>(() => {
    if (!router.isReady) {
      return '';
    }

    const { view: value } = router.query;

    return getQueryParam(value);
  }, [router.isReady, router.query]);

  if (loadingServers) {
    return (
      <div>
        <Head>
          <title>Loading...</title>
        </Head>
        <Header />
        <PageBody>
          <Panel>
            <Spinner mt={0} />
          </Panel>
        </PageBody>
      </div>
    );
  }

  if (!server) {
    return (
      <div>
        <Head>
          <title>Server?</title>
        </Head>
        <Header />
        <PageBody>
          <Panel>
            <MessageBox>
              Couldn&apos;t find server {router.query.name || router.query.uuid}
              . {fetchError?.message}
            </MessageBox>
          </Panel>
        </PageBody>
      </div>
    );
  }

  const views: Record<string, React.ReactNode> = {
    vnc: (
      <MuiBox className={classes.fullView}>
        <FullSize
          node={server.anvil}
          onClickCloseButton={() => {
            const query = setQueryParam(router, 'view');

            router.replace({ query }, undefined, { shallow: true });
          }}
          server={server}
        />
      </MuiBox>
    ),
  };

  return (
    <StyledDiv>
      <Head>
        <title>{server.name}</title>
      </Head>
      <Header />
      {views[view] ?? (
        <PageBody>
          <ManageServer
            serverUuid={server.uuid}
            slotProps={{
              preview: {
                onClick: () => {
                  const query = setQueryParam(router, 'view', 'vnc');

                  router.replace({ query }, undefined, { shallow: true });
                },
              },
            }}
          />
        </PageBody>
      )}
    </StyledDiv>
  );
};

export default Server;
