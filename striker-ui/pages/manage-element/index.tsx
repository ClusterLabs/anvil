import Head from 'next/head';
import { useRouter } from 'next/router';
import { FC, ReactElement, useEffect, useMemo, useState } from 'react';

import api from '../../lib/api';
import getQueryParam from '../../lib/getQueryParam';
import Grid from '../../components/Grid';
import handleAPIError from '../../lib/handleAPIError';
import Header from '../../components/Header';
import { Panel } from '../../components/Panels';
import PrepareHostForm from '../../components/PrepareHostForm';
import PrepareNetworkForm from '../../components/PrepareNetworkForm';
import Spinner from '../../components/Spinner';
import Tab from '../../components/Tab';
import TabContent from '../../components/TabContent';
import Tabs from '../../components/Tabs';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

const MAP_TO_PAGE_TITLE: Record<string, string> = {
  'prepare-host': 'Prepare Host',
  'prepare-network': 'Prepare Network',
  'manage-fence-devices': 'Manage Fence Devices',
  'manage-upses': 'Manage UPSes',
  'manage-manifests': 'Manage Manifests',
};
const PAGE_TITLE_LOADING = 'Loading';
const STEP_CONTENT_GRID_COLUMNS = { md: 8, sm: 6, xs: 1 };
const STEP_CONTENT_GRID_CENTER_COLUMN = { md: 6, sm: 4, xs: 1 };

const PrepareHostTabContent: FC = () => (
  <Grid
    columns={STEP_CONTENT_GRID_COLUMNS}
    layout={{
      'preparehost-left-column': {},
      'preparehost-center-column': {
        children: <PrepareHostForm />,
        ...STEP_CONTENT_GRID_CENTER_COLUMN,
      },
    }}
  />
);

const PrepareNetworkTabContent: FC = () => {
  const isFirstRender = useIsFirstRender();

  const { protect } = useProtect();

  const [hostOverviewList, setHostOverviewList] = useProtectedState<
    APIHostOverviewList | undefined
  >(undefined, protect);
  const [hostSubTabId, setHostSubTabId] = useState<string | false>(false);

  const hostSubTabs = useMemo(() => {
    let result: ReactElement | undefined;

    if (hostOverviewList) {
      const hostOverviewPairs = Object.entries(hostOverviewList);

      result = (
        <Tabs
          onChange={(event, newSubTabId) => {
            setHostSubTabId(newSubTabId);
          }}
          orientation="vertical"
          value={hostSubTabId}
        >
          {hostOverviewPairs.map(([hostUUID, { shortHostName }]) => (
            <Tab
              key={`prepare-network-${hostUUID}`}
              label={shortHostName}
              value={hostUUID}
            />
          ))}
        </Tabs>
      );
    } else {
      result = <Spinner mt={0} />;
    }

    return result;
  }, [hostOverviewList, hostSubTabId]);

  if (isFirstRender) {
    api
      .get<APIHostOverviewList>('/host', { params: { types: 'node,dr' } })
      .then(({ data }) => {
        setHostOverviewList(data);
        setHostSubTabId(Object.keys(data)[0]);
      })
      .catch((error) => {
        handleAPIError(error);
      });
  }

  return (
    <Grid
      columns={STEP_CONTENT_GRID_COLUMNS}
      layout={{
        'preparenetwork-left-column': {
          children: <Panel>{hostSubTabs}</Panel>,
          sm: 2,
        },
        'preparenetwork-center-column': {
          children: (
            <PrepareNetworkForm
              expectUUID
              hostUUID={hostSubTabId || undefined}
            />
          ),
          ...STEP_CONTENT_GRID_CENTER_COLUMN,
        },
      }}
    />
  );
};

const ManageElement: FC = () => {
  const {
    isReady,
    query: { step: rawStep },
  } = useRouter();

  const [pageTabId, setPageTabId] = useState<string | false>(false);
  const [pageTitle, setPageTitle] = useState<string>(PAGE_TITLE_LOADING);

  useEffect(() => {
    if (isReady) {
      let step = getQueryParam(rawStep, {
        fallbackValue: 'prepare-host',
      });

      if (!MAP_TO_PAGE_TITLE[step]) {
        step = 'prepare-host';
      }

      if (pageTitle === PAGE_TITLE_LOADING) {
        setPageTitle(MAP_TO_PAGE_TITLE[step]);
      }

      if (!pageTabId) {
        setPageTabId(step);
      }
    }
  }, [isReady, pageTabId, pageTitle, rawStep]);

  return (
    <>
      <Head>
        <title>{pageTitle}</title>
      </Head>
      <Header />
      <Panel>
        <Tabs
          onChange={(event, newTabId) => {
            setPageTabId(newTabId);
            setPageTitle(MAP_TO_PAGE_TITLE[newTabId]);
          }}
          orientation={{ xs: 'vertical', sm: 'horizontal' }}
          value={pageTabId}
        >
          <Tab label="Prepare host" value="prepare-host" />
          <Tab label="Prepare network" value="prepare-network" />
          <Tab label="Manage fence devices" value="manage-fence-devices" />
        </Tabs>
      </Panel>
      <TabContent changingTabId={pageTabId} tabId="prepare-host">
        <PrepareHostTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId="prepare-network">
        <PrepareNetworkTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId="manage-fence-devices">
        {}
      </TabContent>
    </>
  );
};

export default ManageElement;
