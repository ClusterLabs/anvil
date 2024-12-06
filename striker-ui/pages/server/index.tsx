import { Box, styled } from '@mui/material';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { useCallback, useMemo } from 'react';

import { FullSize } from '../../components/Display';
import Header from '../../components/Header';
import { ManageServer } from '../../components/ManageServer';
import MessageBox from '../../components/MessageBox';
import PageBody from '../../components/PageBody';
import { Panel } from '../../components/Panels';
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

const Server = (): JSX.Element => {
  const router = useRouter();

  const {
    data: servers,
    error: fetchError,
    loading: loadingServers,
  } = useFetch<APIServerOverviewList, APIServerOverview | undefined>('/server');

  const setQueryParam = useCallback(
    (
      previous: typeof router.query,
      key: string,
      value?: string,
    ): typeof router.query => {
      let query;

      // No value means removing the param
      if (value === undefined) {
        const { [key]: rm, ...rest } = previous;

        query = rest;
      } else {
        query = { ...previous, [key]: value };
      }

      return query;
    },
    [router],
  );

  const server = useMemo(() => {
    if (!servers || !router.isReady) {
      return undefined;
    }

    let result: APIServerOverview | undefined;

    const { name, uuid } = router.query;

    if (name) {
      result = Object.values(servers).find((value) => value.name === name);
    } else if (uuid) {
      const key = typeof uuid === 'string' ? uuid : uuid[0];

      result = servers[key];
    }

    return result;
  }, [router.isReady, router.query, servers]);

  const view = useMemo<string>(() => {
    if (!router.isReady) {
      return '';
    }

    const { view: value } = router.query;

    if (!value) {
      return '';
    }

    return typeof value === 'string' ? value : value[0];
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
              . {fetchError}
            </MessageBox>
          </Panel>
        </PageBody>
      </div>
    );
  }

  const views: Record<string, React.ReactNode> = {
    vnc: (
      <Box className={classes.fullView}>
        <FullSize
          onClickCloseButton={() => {
            const query = setQueryParam(router.query, 'view');

            router.push({ query });
          }}
          serverUUID={server.uuid}
          serverName={server.name}
        />
      </Box>
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
                  const query = setQueryParam(router.query, 'view', 'vnc');

                  router.push({ query });
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
