import Head from 'next/head';
import { useRouter } from 'next/router';
import { FC, ReactElement, useEffect, useMemo, useState } from 'react';

import api from '../../lib/api';
import getQueryParam from '../../lib/getQueryParam';
import Grid from '../../components/Grid';
import handleAPIError from '../../lib/handleAPIError';
import Header from '../../components/Header';
import ManageFencePanel from '../../components/ManageFence';
import ManageManifestPanel from '../../components/ManageManifest';
import ManageUpsPanel from '../../components/ManageUps';
import { Panel } from '../../components/Panels';
import PrepareHostForm from '../../components/PrepareHostForm';
import PrepareNetworkForm from '../../components/PrepareNetworkForm';
import Spinner from '../../components/Spinner';
import Tab from '../../components/Tab';
import TabContent from '../../components/TabContent';
import Tabs from '../../components/Tabs';
import useIsFirstRender from '../../hooks/useIsFirstRender';

const TAB_ID_PREPARE_HOST = 'prepare-host';
const TAB_ID_PREPARE_NETWORK = 'prepare-network';
const TAB_ID_MANAGE_FENCE = 'manage-fence';
const TAB_ID_MANAGE_UPS = 'manage-ups';
const TAB_ID_MANAGE_MANIFEST = 'manage-manifest';

const MAP_TO_PAGE_TITLE: Record<string, string> = {
  [TAB_ID_PREPARE_HOST]: 'Prepare Host',
  [TAB_ID_PREPARE_NETWORK]: 'Prepare Network',
  [TAB_ID_MANAGE_FENCE]: 'Manage Fence Devices',
  [TAB_ID_MANAGE_UPS]: 'Manage UPSes',
  [TAB_ID_MANAGE_MANIFEST]: 'Manage Manifests',
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

  const [hostOverviewList, setHostOverviewList] = useState<
    APIHostOverviewList | undefined
  >();
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
              key={`${TAB_ID_PREPARE_NETWORK}-${hostUUID}`}
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
      .get<APIHostOverviewList>('/host', { params: { types: ['dr', 'node'] } })
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

const ManageFenceTabContent: FC = () => (
  <Grid
    columns={STEP_CONTENT_GRID_COLUMNS}
    layout={{
      'managefence-left-column': {},
      'managefence-center-column': {
        children: <ManageFencePanel />,
        ...STEP_CONTENT_GRID_CENTER_COLUMN,
      },
    }}
  />
);

const ManageUpsTabContent: FC = () => (
  <Grid
    columns={STEP_CONTENT_GRID_COLUMNS}
    layout={{
      'manageups-left-column': {},
      'manageups-center-column': {
        children: <ManageUpsPanel />,
        ...STEP_CONTENT_GRID_CENTER_COLUMN,
      },
    }}
  />
);

const ManageManifestContent: FC = () => (
  <Grid
    columns={STEP_CONTENT_GRID_COLUMNS}
    layout={{
      'managemanifest-left-column': {},
      'managemanifest-center-column': {
        children: <ManageManifestPanel />,
        ...STEP_CONTENT_GRID_CENTER_COLUMN,
      },
    }}
  />
);

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
        fallbackValue: TAB_ID_PREPARE_HOST,
      });

      if (!MAP_TO_PAGE_TITLE[step]) {
        step = TAB_ID_PREPARE_HOST;
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
          <Tab label="Prepare host" value={TAB_ID_PREPARE_HOST} />
          <Tab label="Prepare network" value={TAB_ID_PREPARE_NETWORK} />
          <Tab label="Manage fence devices" value={TAB_ID_MANAGE_FENCE} />
          <Tab label="Manage UPSes" value={TAB_ID_MANAGE_UPS} />
          <Tab label="Manage manifests" value={TAB_ID_MANAGE_MANIFEST} />
        </Tabs>
      </Panel>
      <TabContent changingTabId={pageTabId} tabId={TAB_ID_PREPARE_HOST}>
        <PrepareHostTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId={TAB_ID_PREPARE_NETWORK}>
        <PrepareNetworkTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId={TAB_ID_MANAGE_FENCE}>
        <ManageFenceTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId={TAB_ID_MANAGE_UPS}>
        <ManageUpsTabContent />
      </TabContent>
      <TabContent changingTabId={pageTabId} tabId={TAB_ID_MANAGE_MANIFEST}>
        <ManageManifestContent />
      </TabContent>
    </>
  );
};

export default ManageElement;
