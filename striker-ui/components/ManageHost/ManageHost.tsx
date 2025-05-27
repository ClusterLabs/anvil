import { Grid } from '@mui/material';
import { useState } from 'react';

import { toHostDetailCalcable } from '../../lib/api_converters';
import Divider from '../Divider';
import HostGeneralInfo from './HostGeneralInfo';
import HostServerList from './HostServerList';
import HostStorageList from './HostStorageList';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import Tab from '../Tab';
import TabContent from '../TabContent';
import Tabs from '../Tabs';
import { HeaderText } from '../Text';
import useFetch from '../../hooks/useFetch';

const tabs = {
  general: {
    label: 'General',
    value: 'general',
  },
  servers: {
    label: 'Servers',
    value: 'servers',
  },
  storage: {
    label: 'Storage',
    value: 'storage',
  },
};

const ManageDrHost: React.FC<ManageHostProps> = (props) => {
  const { uuid } = props;

  const [tabId, setTabId] = useState<string>(tabs.general.value);

  const { altData: host, loading } = useFetch<
    APIHostDetail,
    APIHostDetailCalcable
  >(`/host/${uuid}`, {
    mod: toHostDetailCalcable,
    periodic: true,
  });

  return (
    <Panel>
      {loading && <Spinner mt={0} />}
      {host && (
        <Grid container spacing="1em">
          <Grid
            item
            width={{
              xs: '100%',
              sm: '14em',
              md: '20em',
            }}
          >
            <Grid container rowSpacing="1em">
              <Grid item width="100%">
                <Tabs
                  onChange={(event, id) => {
                    setTabId(id);
                  }}
                  orientation="vertical"
                  value={tabId}
                >
                  <Tab {...tabs.general} label={host.short} />

                  <Tab
                    disabled
                    icon={<Divider sx={{ width: '100%' }} />}
                    label=""
                  />

                  <Tab {...tabs.servers} />

                  <Tab {...tabs.storage} />
                </Tabs>
              </Grid>
            </Grid>
          </Grid>
          <Grid
            display={{
              xs: 'none',
              sm: 'initial',
            }}
            item
          >
            <Divider orientation="vertical" />
          </Grid>
          <Grid item xs>
            <TabContent changingTabId={tabId} tabId={tabs.general.value}>
              <PanelHeader>
                <HeaderText>{tabs.general.label}</HeaderText>
              </PanelHeader>
              <HostGeneralInfo host={host} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.servers.value}>
              <PanelHeader>
                <HeaderText>{tabs.servers.label}</HeaderText>
              </PanelHeader>
              <HostServerList host={host} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.storage.value}>
              <PanelHeader>
                <HeaderText>{tabs.storage.label}</HeaderText>
              </PanelHeader>
              <HostStorageList host={host} />
            </TabContent>
          </Grid>
        </Grid>
      )}
    </Panel>
  );
};

export default ManageDrHost;
