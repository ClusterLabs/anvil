import Grid from '@mui/material/Grid';
import styled from '@mui/material/styles/styled';
import { useRef, useState } from 'react';

import {
  Preview,
  PreviewBox as BasePreviewBox,
  PreviewFrame,
} from '../Display';
import Divider from '../Divider';
import { Panel, PanelHeader } from '../Panels';
import ServerBootOrderForm from './ServerBootOrderForm';
import ServerCpuForm from './ServerCpuForm';
import ServerDeletion from './ServerDeletion';
import ServerDiskList from './ServerDiskList';
import ServerInterfaceList from './ServerInterfaceList';
import ServerMemoryForm from './ServerMemoryForm';
import ServerMigration from './ServerMigration';
import ServerProtectForm from './ServerProtectForm';
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
  delete: {
    label: 'Deletion',
    value: 'deletion',
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
  protect: {
    label: 'Disaster recovery',
    value: 'protect',
  },
  startDependency: {
    label: 'Start dependency',
    value: 'start-dependency',
  },
};

const PreviewBox = styled(BasePreviewBox)(({ theme }) => {
  const getHeight = (width = '0') => `calc(${width} * 0.6)`;

  return {
    width: '100%',

    [theme.breakpoints.up('xs')]: {
      height: getHeight('100vw'),
    },

    [theme.breakpoints.up('sm')]: {
      height: '6em',
    },

    [theme.breakpoints.up('md')]: {
      height: '9em',
    },
  };
});

const ManageServer: React.FC<ManageServerProps> = (props) => {
  const { slotProps, serverUuid } = props;

  const [tabId, setTabId] = useState<string>(tabs.general.value);

  const { data: servers, mutate: updateServers } =
    useFetch<APIServerOverviewList>('/server');

  const { data: detail } = useFetch<APIServerDetail>(`/server/${serverUuid}`, {
    refreshInterval: 3000,
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
                <PreviewFrame server={detail}>
                  <Preview
                    server={detail}
                    slots={{
                      screenshotBox: <PreviewBox />,
                    }}
                    {...slotProps?.preview}
                  />
                </PreviewFrame>
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
                  <Tab {...tabs.general} label={detail.name} />

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

                  <Tab {...tabs.bootOrder} />

                  <Tab {...tabs.cpu} />

                  <Tab {...tabs.disks} />

                  <Tab {...tabs.interfaces} />

                  <Tab {...tabs.memory} />

                  <Tab {...tabs.migration} />

                  <Tab {...tabs.name} />

                  <Tab {...tabs.protect} />

                  <Tab {...tabs.startDependency} />

                  <Tab {...tabs.delete} />
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
                    value: detail.host ? detail.host.short : 'None',
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

            <TabContent changingTabId={tabId} tabId={tabs.delete.value}>
              <PanelHeader>
                <HeaderText>{tabs.delete.label}</HeaderText>
              </PanelHeader>
              <ServerDeletion detail={detail} tools={formTools.current} />
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

            <TabContent changingTabId={tabId} tabId={tabs.protect.value}>
              <PanelHeader>
                <HeaderText>{tabs.protect.label}</HeaderText>
              </PanelHeader>
              <ServerProtectForm detail={detail} tools={formTools.current} />
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
