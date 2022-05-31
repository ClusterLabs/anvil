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

const createServerPreviewContainer = (servers: ServerOverviewMetadata[]) => (
  <Box
    sx={{
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',

      '& > *': {
        width: { xs: '20em', md: '30em' },
      },
    }}
  >
    {servers.map(({ serverName, serverUUID }) => (
      <Preview
        key={`server-preview-${serverUUID}`}
        isShowControls={false}
        isUseInnerPanel
        serverName={serverName}
        uuid={serverUUID}
      />
    ))}
  </Box>
);

const filterServers = (
  allServers: ServerOverviewMetadata[],
  searchTerm: string,
) =>
  searchTerm === ''
    ? {
        exclude: allServers,
        include: [],
      }
    : allServers.reduce<{
        exclude: ServerOverviewMetadata[];
        include: ServerOverviewMetadata[];
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
  const [allServers, setAllServers] = useState<ServerOverviewMetadata[]>([]);
  const [excludeServers, setExcludeServers] = useState<
    ServerOverviewMetadata[]
  >([]);
  const [includeServers, setIncludeServers] = useState<
    ServerOverviewMetadata[]
  >([]);

  const [inputSearchTerm, setInputSearchTerm] = useState<string>('');

  const updateServerList = (
    ...filterArgs: Parameters<typeof filterServers>
  ) => {
    const { exclude, include } = filterServers(...filterArgs);

    setExcludeServers(exclude);
    setIncludeServers(include);
  };

  const { isLoading } = periodicFetch<ServerOverviewMetadata[]>(
    `${API_BASE_URL}/server`,
    {
      onSuccess: (data = []) => {
        setAllServers(data);

        updateServerList(data, inputSearchTerm);
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
