import Head from 'next/head';
import { useRouter } from 'next/router';
import { FC, useEffect, useState } from 'react';

import getQueryParam from '../../lib/getQueryParam';
import Header from '../../components/Header';
import ManageFencePanel from '../../components/ManageFence';
import { ManageHost } from '../../components/ManageHost';
import { ManageHostNetwork } from '../../components/ManageHostNetwork';
import ManageManifestPanel from '../../components/ManageManifest';
import ManageUpsPanel from '../../components/ManageUps';
import PageBody from '../../components/PageBody';
import { Panel, PanelHeader } from '../../components/Panels';
import Tab from '../../components/Tab';
import TabContent from '../../components/TabContent';
import Tabs from '../../components/Tabs';
import { HeaderText } from '../../components/Text';

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

const PrepareHostTabContent: FC = () => (
  <PageBody>
    <Panel>
      <PanelHeader>
        <HeaderText>Hosts</HeaderText>
      </PanelHeader>
      <ManageHost />
    </Panel>
  </PageBody>
);

const PrepareNetworkTabContent: FC = () => (
  <PageBody>
    <ManageHostNetwork />
  </PageBody>
);

const ManageFenceTabContent: FC = () => (
  <PageBody>
    <ManageFencePanel />
  </PageBody>
);

const ManageUpsTabContent: FC = () => (
  <PageBody>
    <ManageUpsPanel />
  </PageBody>
);

const ManageManifestContent: FC = () => (
  <PageBody>
    <ManageManifestPanel />
  </PageBody>
);

const ManageElement: FC = () => {
  const { isReady, push, query } = useRouter();

  const [pageTabId, setPageTabId] = useState<string | false>(false);
  const [pageTitle, setPageTitle] = useState<string>(PAGE_TITLE_LOADING);

  useEffect(() => {
    if (!isReady) return;

    const { step: rawStep } = query;

    let step = getQueryParam(rawStep, {
      fallbackValue: TAB_ID_PREPARE_HOST,
    });

    if (!MAP_TO_PAGE_TITLE[step]) {
      step = TAB_ID_PREPARE_HOST;
    }

    push({ query: { ...query, step } }, undefined, { shallow: true });

    if (pageTitle === PAGE_TITLE_LOADING) {
      setPageTitle(MAP_TO_PAGE_TITLE[step]);
    }

    if (!pageTabId) {
      setPageTabId(step);
    }

    // Everything should be available when router is ready.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isReady]);

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

            push({ query: { ...query, step: newTabId } }, undefined, {
              shallow: true,
            });
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
