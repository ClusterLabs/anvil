import { Add as AddIcon } from '@mui/icons-material';
import { Box, Divider, Grid } from '@mui/material';
import Head from 'next/head';
import { FC, useState } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import { DIVIDER } from '../lib/consts/DEFAULT_THEME';

import AnvilSummaryList from '../components/Anvils/AnvilSummaryList';
import { Preview } from '../components/Display';
import fetchJSON from '../lib/fetchers/fetchJSON';
import Header from '../components/Header';
import IconButton from '../components/IconButton';
import Link from '../components/Link';
import OutlinedInput from '../components/OutlinedInput';
import { Panel, PanelHeader } from '../components/Panels';
import ProvisionServerDialog from '../components/ProvisionServerDialog';
import Spinner from '../components/Spinner';
import { HeaderText } from '../components/Text';
import { last } from '../lib/time';
import useFetch from '../hooks/useFetch';

type ServerListItem = APIServerOverview & {
  isScreenshotStale?: boolean;
  loading?: boolean;
  screenshot: string;
  timestamp: number;
};

const createServerPreviewContainer = (servers: ServerListItem[]) => (
  <Grid
    alignContent="stretch"
    columns={{ xs: 1, sm: 2, md: 3, xl: 4 }}
    container
    spacing="1em"
  >
    {servers.map(
      ({
        anvil: { name: anvilName, uuid: anvilUuid },
        isScreenshotStale,
        loading,
        screenshot,
        name: serverName,
        state: serverState,
        uuid: serverUuid,
        timestamp,
      }) => (
        <Grid
          item
          key={`${serverUuid}-preview`}
          sx={{
            minWidth: '20em',

            '& > div': {
              height: '100%',
              marginBottom: 0,
              marginTop: 0,
            },
          }}
          xs={1}
        >
          <Preview
            externalPreview={screenshot}
            externalTimestamp={timestamp}
            headerEndAdornment={[
              <Link
                href={`/server?uuid=${serverUuid}&server_name=${serverName}&server_state=${serverState}`}
                key={`server_list_to_server_${serverUuid}`}
              >
                {serverName}
              </Link>,
              <Link
                href={`/anvil?anvil_uuid=${anvilUuid}`}
                key={`server_list_server_${serverUuid}_to_anvil_${anvilUuid}`}
                sx={{
                  opacity: 0.7,
                }}
              >
                {anvilName}
              </Link>,
            ]}
            hrefPreview={`/server?uuid=${serverUuid}&server_name=${serverName}&server_state=${serverState}&vnc=1`}
            isExternalLoading={loading}
            isExternalPreviewStale={isScreenshotStale}
            isFetchPreview={false}
            isShowControls={false}
            isUseInnerPanel
            serverState={serverState}
            serverUUID={serverUuid}
          />
        </Grid>
      ),
    )}
  </Grid>
);

const filterServers = (allServers: ServerListItem[], searchTerm: string) =>
  searchTerm === ''
    ? {
        exclude: allServers,
        include: [],
      }
    : allServers.reduce<{
        exclude: ServerListItem[];
        include: ServerListItem[];
      }>(
        (reduceContainer, server) => {
          const { name } = server;

          if (name.includes(searchTerm)) {
            reduceContainer.include.push(server);
          } else {
            reduceContainer.exclude.push(server);
          }

          return reduceContainer;
        },
        { exclude: [], include: [] },
      );

const Dashboard: FC = () => {
  const [allServers, setAllServers] = useState<ServerListItem[]>([]);
  const [excludeServers, setExcludeServers] = useState<ServerListItem[]>([]);
  const [includeServers, setIncludeServers] = useState<ServerListItem[]>([]);

  const [inputSearchTerm, setInputSearchTerm] = useState<string>('');

  const [isOpenProvisionServerDialog, setIsOpenProvisionServerDialog] =
    useState<boolean>(false);

  const updateServerList = (
    ...filterArgs: Parameters<typeof filterServers>
  ) => {
    const { exclude, include } = filterServers(...filterArgs);

    setExcludeServers(exclude);
    setIncludeServers(include);
  };

  const { loading } = useFetch<APIServerOverviewList>('/server', {
    onSuccess: (data) => {
      const values = Object.values(data);

      const serverListItems = values.map<ServerListItem>((server) => {
        const { uuid: serverUuid } = server;

        const previousScreenshot: string =
          allServers.find(({ uuid }) => uuid === serverUuid)?.screenshot || '';

        const item: ServerListItem = {
          ...server,
          loading: true,
          screenshot: previousScreenshot,
          timestamp: 0,
        };

        fetchJSON<{ screenshot: string; timestamp: number }>(
          `${API_BASE_URL}/server/${serverUuid}?ss=1`,
        )
          .then(({ screenshot, timestamp }) => {
            if (screenshot.length === 0) return;

            item.isScreenshotStale = !last(timestamp, 300);
            item.loading = false;
            item.screenshot = screenshot;
            item.timestamp = timestamp;

            const allServersWithScreenshots = [...serverListItems];

            setAllServers(allServersWithScreenshots);
            // Don't update servers to include or exclude here to avoid
            // updating using an outdated input search term. Remember this
            // block is async and takes a lot longer to complete compared to
            // the overview fetch.
          })
          .catch(() => {
            item.isScreenshotStale = true;
          })
          .finally(() => {
            item.loading = false;
          });

        return item;
      });

      setAllServers(serverListItems);
      updateServerList(serverListItems, inputSearchTerm);
    },
    refreshInterval: 60000,
  });

  return (
    <Box>
      <Head>
        <title>Dashboard</title>
      </Head>
      <Header />
      <Panel>
        {loading ? (
          <Spinner />
        ) : (
          <>
            <PanelHeader sx={{ marginBottom: '2em' }}>
              <HeaderText>Servers</HeaderText>
              <IconButton onClick={() => setIsOpenProvisionServerDialog(true)}>
                <AddIcon />
              </IconButton>
              <OutlinedInput
                placeholder="Search by server name"
                onChange={({ target: { value } }) => {
                  setInputSearchTerm(value);
                  updateServerList(allServers, value);
                }}
                sx={{ minWidth: '16em' }}
                value={inputSearchTerm}
              />
            </PanelHeader>
            {createServerPreviewContainer(includeServers)}
            {includeServers.length > 0 && (
              <Divider sx={{ backgroundColor: DIVIDER }} />
            )}
            {createServerPreviewContainer(excludeServers)}
          </>
        )}
      </Panel>
      <AnvilSummaryList />
      <ProvisionServerDialog
        dialogProps={{ open: isOpenProvisionServerDialog }}
        onClose={() => {
          setIsOpenProvisionServerDialog(false);
        }}
      />
    </Box>
  );
};

export default Dashboard;
