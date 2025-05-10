import Head from 'next/head';
import { useRouter } from 'next/router';
import { useMemo } from 'react';

import getListValueFromRouterQuery from '../../lib/getListValueFromRouterQuery';
import Header from '../../components/Header';
import { ManageHost } from '../../components/ManageHost';
import MessageBox from '../../components/MessageBox';
import PageBody from '../../components/PageBody';
import { Panel } from '../../components/Panels';
import Spinner from '../../components/Spinner';
import useFetch from '../../hooks/useFetch';

const Host: React.FC = () => {
  const router = useRouter();

  const {
    data: hosts,
    error: fetchError,
    loading: loadingHosts,
  } = useFetch<APIHostOverviewList>('/host');

  const host = useMemo(
    () =>
      getListValueFromRouterQuery(
        hosts,
        router,
        (name) => (value) => value.shortHostName === name,
      ),
    [hosts, router],
  );

  const title = useMemo<React.ReactNode>(() => {
    if (loadingHosts) {
      return 'Loading...';
    }

    if (!host) {
      return 'Host?';
    }

    return host.shortHostName;
  }, [host, loadingHosts]);

  const body = useMemo<React.ReactNode>(() => {
    const { name, uuid } = router.query;

    if (loadingHosts) {
      return (
        <Panel>
          <Spinner mt={0} />
        </Panel>
      );
    }

    if (!host) {
      return (
        <Panel>
          <MessageBox>
            Failed to find host {name || uuid}. {fetchError?.message}
          </MessageBox>
        </Panel>
      );
    }

    return <ManageHost uuid={host.hostUUID} />;
  }, [fetchError?.message, host, loadingHosts, router.query]);

  return (
    <div>
      <Head>
        <title>{title}</title>
      </Head>
      <Header />
      <PageBody>{body}</PageBody>
    </div>
  );
};

export default Host;
