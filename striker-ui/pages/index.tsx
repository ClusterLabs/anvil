import Head from 'next/head';
import { NextRouter, useRouter } from 'next/router';
import { FC, useEffect, useRef, useState } from 'react';
import { Box, Divider } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import { DIVIDER } from '../lib/consts/DEFAULT_THEME';

import { Preview } from '../components/Display';
import fetchJSON from '../lib/fetchers/fetchJSON';
import Header from '../components/Header';
import IconButton from '../components/IconButton';
import Link from '../components/Link';
import OutlinedInput from '../components/OutlinedInput';
import { Panel, PanelHeader } from '../components/Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import ProvisionServerDialog from '../components/ProvisionServerDialog';
import Spinner from '../components/Spinner';

type ServerListItem = ServerOverviewMetadata & {
  isScreenshotStale?: boolean;
  screenshot: string;
};

const createServerPreviewContainer = (
  servers: ServerListItem[],
  router: NextRouter,
) => (
  <Box
    sx={{
      display: 'flex',
      flexDirection: 'row',
      flexWrap: 'wrap',

      '& > *': {
        width: { xs: '20em', md: '24em' },
      },

      '& > :not(:last-child)': {
        marginRight: '2em',
      },
    }}
  >
    {servers.map(
      ({
        anvilName,
        anvilUUID,
        isScreenshotStale,
        screenshot,
        serverName,
        serverUUID,
      }) => (
        <Preview
          externalPreview={screenshot}
          headerEndAdornment={[
            <Link
              href={`/server?uuid=${serverUUID}&server_name=${serverName}`}
              key={`server_list_to_server_${serverUUID}`}
            >
              {serverName}
            </Link>,
            <Link
              href={`/anvil?anvil_uuid=${anvilUUID}`}
              key={`server_list_server_${serverUUID}_to_anvil_${anvilUUID}`}
              sx={{
                opacity: 0.7,
              }}
            >
              {anvilName}
            </Link>,
          ]}
          isExternalPreviewStale={isScreenshotStale}
          isFetchPreview={false}
          isShowControls={false}
          isUseInnerPanel
          key={`server-preview-${serverUUID}`}
          onClickPreview={() => {
            router.push(
              `/server?uuid=${serverUUID}&server_name=${serverName}&vnc=1`,
            );
          }}
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
  const componentMountedRef = useRef(true);
  const router = useRouter();

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

    if (!componentMountedRef.current) {
      return;
    }

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
            `${API_BASE_URL}/server/${serverUUID}?ss=1`,
          )
            .then(({ screenshot }) => {
              item.screenshot = screenshot;
              item.isScreenshotStale = false;

              const allServersWithScreenshots = [...serverListItems];

              if (!componentMountedRef.current) {
                return;
              }

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

  useEffect(
    () => () => {
      componentMountedRef.current = false;
    },
    [],
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
                sx={{ marginRight: '.6em' }}
                value={inputSearchTerm}
              />
              <IconButton onClick={() => setIsOpenProvisionServerDialog(true)}>
                <AddIcon />
              </IconButton>
            </PanelHeader>
            {createServerPreviewContainer(includeServers, router)}
            {includeServers.length > 0 && (
              <Divider sx={{ backgroundColor: DIVIDER }} />
            )}
            {createServerPreviewContainer(excludeServers, router)}
          </>
        )}
      </Panel>
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
