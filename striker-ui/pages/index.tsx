import Head from 'next/head';
import { FC, useState } from 'react';
import { Box, Divider } from '@mui/material';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import { DIVIDER } from '../lib/consts/DEFAULT_THEME';

import { Preview } from '../components/Display';
import Header from '../components/Header';
import OutlinedInput from '../components/OutlinedInput';
import { Panel, PanelHeader } from '../components/Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from '../components/Spinner';
import fetchJSON from '../lib/fetchers/fetchJSON';

type ServerListItem = ServerOverviewMetadata & {
  isScreenshotStale?: boolean;
  screenshot: string;
};

const createServerPreviewContainer = (servers: ServerListItem[]) => (
  <Box
    sx={{
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',

      '& > *': {
        width: { xs: '20em', md: '30em' },
      },

      '& > :not(:last-child)': {
        marginRight: '2em',
      },
    }}
  >
    {servers.map(
      ({ isScreenshotStale, screenshot, serverName, serverUUID }) => (
        <Preview
          key={`server-preview-${serverUUID}`}
          isExternalPreviewStale={isScreenshotStale}
          isFetchPreview={false}
          isShowControls={false}
          isUseInnerPanel
          externalPreview={screenshot}
          serverName={serverName}
          serverUUID={serverUUID}
        />
      ),
    )}
  </Box>
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
          const { serverName } = server;

          if (serverName.includes(searchTerm)) {
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

  const updateServerList = (
    ...filterArgs: Parameters<typeof filterServers>
  ) => {
    const { exclude, include } = filterServers(...filterArgs);

    setExcludeServers(exclude);
    setIncludeServers(include);
  };

  const { isLoading } = periodicFetch<ServerListItem[]>(
    `${API_BASE_URL}/server`,
    {
      onSuccess: (data = []) => {
        const serverListItems: ServerListItem[] = (
          data as ServerOverviewMetadata[]
        ).map((serverOverview) => {
          const { serverUUID } = serverOverview;
          const previousScreenshot: string =
            allServers.find(({ serverUUID: uuid }) => uuid === serverUUID)
              ?.screenshot || '';
          const item: ServerListItem = {
            ...serverOverview,
            screenshot: previousScreenshot,
          };

          fetchJSON<{ screenshot: string }>(
            `${API_BASE_URL}/server/${serverUUID}?ss`,
          )
            .then(({ screenshot }) => {
              item.screenshot = screenshot;
              item.isScreenshotStale = false;

              const allServersWithScreenshots = [...serverListItems];

              setAllServers(allServersWithScreenshots);
              // Don't update servers to include or exclude here to avoid
              // updating using an outdated input search term. Remember this
              // block is async and takes a lot longer to complete compared to
              // the overview fetch.
            })
            .catch(() => {
              item.isScreenshotStale = true;
            });

          return item;
        });

        setAllServers(serverListItems);
        updateServerList(serverListItems, inputSearchTerm);
      },
      refreshInterval: 60000,
    },
  );

  return (
    <Box>
      <Head>
        <title>Dashboard</title>
      </Head>
      <Header />
      <Panel>
        {isLoading ? (
          <Spinner />
        ) : (
          <>
            <PanelHeader>
              <OutlinedInput
                placeholder="Search by server name"
                onChange={({ target: { value } }) => {
                  setInputSearchTerm(value);
                  updateServerList(allServers, value);
                }}
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
    </Box>
  );
};

export default Dashboard;
