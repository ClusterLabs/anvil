import { Grid } from '@mui/material';
import { FC, useRef, useState } from 'react';

import { Preview } from '../Display';
import Divider from '../Divider';
import { Panel, PanelHeader } from '../Panels';
import ServerBootOrderForm from './ServerBootOrderForm';
import ServerCpuForm from './ServerCpuForm';
import ServerDiskList from './ServerDiskList';
import ServerInterfaceList from './ServerInterfaceList';
import ServerMemoryForm from './ServerMemoryForm';
import ServerMigration from './ServerMigration';
import ServerRenameForm from './ServerRenameForm';
import ServerStartDependencyForm from './ServerStartDependencyForm';
import Spinner from '../Spinner';
import Tab from '../Tab';
import TabContent from '../TabContent';
import Tabs from '../Tabs';
import { BodyText, HeaderText, MonoText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';

const tabs = {
  bootOrder: {
    label: 'Boot order',
    value: 'boot-order',
  },
  cpu: {
    label: 'CPU',
    value: 'cpu',
  },
  disks: {
    label: 'Disks',
    value: 'disks',
  },
  general: {
    label: 'General',
    value: 'general',
  },
  interfaces: {
    label: 'Interfaces',
    value: 'interfaces',
  },
  memory: {
    label: 'Memory',
    value: 'memory',
  },
  migration: {
    label: 'Migration',
    value: 'migration',
  },
  name: {
    label: 'Name',
    value: 'name',
  },
  startDependency: {
    label: 'Start dependency',
    value: 'start-dependency',
  },
};

const ManageServer: FC<ManageServerProps> = (props) => {
  const { slotProps = {}, serverUuid } = props;

  const [tabId, setTabId] = useState<string>(tabs.general.value);

  const { data: servers, mutate: updateServers } =
    useFetch<APIServerOverviewList>('/server');

  const { data: detail } = useFetch<APIServerDetail>(`/server/${serverUuid}`, {
    refreshInterval: 2000,
  });

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog({
    initial: {
      scrollContent: true,
      wide: true,
    },
  });

  const formTools = useRef<CrudListFormTools>({
    add: { open: () => null },
    confirm: {
      finish: finishConfirm,
      loading: setConfirmDialogLoading,
      open: (v = true) => setConfirmDialogOpen(v),
      prepare: setConfirmDialogProps,
    },
    edit: { open: () => null },
  });

  if (!detail || !servers) {
    return (
      <Panel>
        <Spinner mt={0} />
      </Panel>
    );
  }

  return (
    <>
      <Panel>
        <Grid container spacing="1em">
          <Grid item width={{ xs: '100%', sm: '14em', md: '20em' }}>
            <Grid columns={1} container spacing="1em">
              <Grid item width="100%">
                <Preview
                  isUseInnerPanel
                  onClickPreview={slotProps.preview?.onClick}
                  serverName={detail.name}
                  serverState={detail.state}
                  serverUUID={detail.uuid}
                  slotProps={{
                    innerPanel: { mb: 0, mt: 0 },
                  }}
                />
              </Grid>
              <Grid item width="100%">
                <Tabs
                  onChange={(event, id) => {
                    setTabId(id);

                    if (
                      [
                        tabs.migration.value,
                        tabs.startDependency.value,
                      ].includes(id)
                    ) {
                      updateServers();
                    }
                  }}
                  orientation="vertical"
                  value={tabId}
                >
                  <Tab label={tabs.general.label} value={tabs.general.value} />

                  <Tab
                    disabled
                    icon={
                      <Divider
                        orientation="horizontal"
                        sx={{ width: '100%' }}
                      />
                    }
                    label=""
                  />

                  <Tab
                    label={tabs.bootOrder.label}
                    value={tabs.bootOrder.value}
                  />

                  <Tab label={tabs.cpu.label} value={tabs.cpu.value} />

                  <Tab label={tabs.disks.label} value={tabs.disks.value} />

                  <Tab
                    label={tabs.interfaces.label}
                    value={tabs.interfaces.value}
                  />

                  <Tab label={tabs.memory.label} value={tabs.memory.value} />

                  <Tab
                    label={tabs.migration.label}
                    value={tabs.migration.value}
                  />

                  <Tab label={tabs.name.label} value={tabs.name.value} />

                  <Tab
                    label={tabs.startDependency.label}
                    value={tabs.startDependency.value}
                  />
                </Tabs>
              </Grid>
            </Grid>
          </Grid>
          <Grid display={{ xs: 'none', sm: 'initial' }} item>
            <Divider orientation="vertical" />
          </Grid>
          {/* Take the remaining space with xs=true */}
          <Grid item xs>
            <TabContent changingTabId={tabId} tabId={tabs.general.value}>
              <PanelHeader>
                <HeaderText>{tabs.general.label}</HeaderText>
              </PanelHeader>
              <Grid container rowSpacing="0.4em">
                {[
                  {
                    header: 'UUID',
                    value: detail.uuid,
                  },
                  {
                    header: 'State',
                    value: detail.state,
                  },
                  {
                    header: 'On node',
                    value: `${detail.anvil.name}: ${detail.anvil.description}`,
                  },
                  {
                    header: 'On host',
                    value: `${detail.host.name} (${detail.host.short})`,
                  },
                ].map(({ header, value }) => (
                  <Grid key={`general-${header}`} item width="100%">
                    <Grid columnSpacing="1em" container>
                      <Grid item width="10em">
                        <BodyText>{header}</BodyText>
                      </Grid>
                      <Grid item xs>
                        <MonoText>{value}</MonoText>
                      </Grid>
                    </Grid>
                  </Grid>
                ))}
              </Grid>
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.bootOrder.value}>
              <PanelHeader>
                <HeaderText>{tabs.bootOrder.label}</HeaderText>
              </PanelHeader>
              <ServerBootOrderForm detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.cpu.value}>
              <PanelHeader>
                <HeaderText>{tabs.cpu.label}</HeaderText>
              </PanelHeader>
              <ServerCpuForm detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.disks.value}>
              <PanelHeader>
                <HeaderText>{tabs.disks.label}</HeaderText>
              </PanelHeader>
              <ServerDiskList detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.interfaces.value}>
              <PanelHeader>
                <HeaderText>{tabs.interfaces.label}</HeaderText>
              </PanelHeader>
              <ServerInterfaceList detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.memory.value}>
              <PanelHeader>
                <HeaderText>{tabs.memory.label}</HeaderText>
              </PanelHeader>
              <ServerMemoryForm detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.migration.value}>
              <PanelHeader>
                <HeaderText>{tabs.migration.label}</HeaderText>
              </PanelHeader>
              <ServerMigration detail={detail} tools={formTools.current} />
            </TabContent>

            <TabContent changingTabId={tabId} tabId={tabs.name.value}>
              <PanelHeader>
                <HeaderText>{tabs.name.label}</HeaderText>
              </PanelHeader>
              <ServerRenameForm
                detail={detail}
                tools={formTools.current}
                servers={servers}
              />
            </TabContent>

            <TabContent
              changingTabId={tabId}
              tabId={tabs.startDependency.value}
            >
              <PanelHeader>
                <HeaderText>{tabs.startDependency.label}</HeaderText>
              </PanelHeader>
              <ServerStartDependencyForm
                detail={detail}
                servers={servers}
                tools={formTools.current}
              />
            </TabContent>
          </Grid>
        </Grid>
      </Panel>
      {confirmDialog}
    </>
  );
};

export default ManageServer;
