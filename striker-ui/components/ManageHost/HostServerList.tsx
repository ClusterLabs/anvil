import {
  Grid2 as MuiGrid,
  grid2Classes as muiGridClasses,
} from '@mui/material';
import { useCallback, useMemo } from 'react';

import Link from '../Link';
import List from '../List';
import { BodyText, MonoText } from '../Text';

const HostServerList: React.FC<HostServerListProps> = (props) => {
  const { host } = props;

  const drbdResources = useMemo(
    () =>
      Object.values(host.drbdResources).reduce<
        Record<string, APIHostDrbdResource>
      >((previous, resource) => {
        previous[resource.name] = resource;

        return previous;
      }, {}),
    [host.drbdResources],
  );

  const renderServer = useCallback(
    (key: string, uuid: string): React.ReactNode => {
      const { [uuid]: server } = host.servers.all;

      if (!server) {
        return undefined;
      }

      const { name } = server;

      const { [name]: resource } = drbdResources;

      return (
        <MuiGrid alignItems="center" columnSpacing="1em" container width="100%">
          <MuiGrid>
            <Link href={`/server?name=${name}`} noWrap>
              {name}
            </Link>
          </MuiGrid>
          <MuiGrid
            size="grow"
            sx={{
              [`& > .${muiGridClasses.container}`]: {
                alignItems: 'center',
                width: '100%',

                [`& > .${muiGridClasses.root}:nth-child(odd)`]: {
                  width: '5em',
                },
              },
            }}
          >
            <MuiGrid columnSpacing="0.5em" container>
              <MuiGrid>
                <BodyText>Connection</BodyText>
              </MuiGrid>
              <MuiGrid size="grow">
                <MonoText>{resource.connection.state}</MonoText>
              </MuiGrid>
            </MuiGrid>
            <MuiGrid columnSpacing="0.5em" container>
              <MuiGrid>
                <BodyText>Disk</BodyText>
              </MuiGrid>
              <MuiGrid size="grow">
                <MonoText>{resource.replication.state}</MonoText>
              </MuiGrid>
            </MuiGrid>
          </MuiGrid>
        </MuiGrid>
      );
    },
    [drbdResources, host.servers.all],
  );

  const configuredList = useMemo(
    () => (
      <List
        header="Configured"
        listEmpty="No server(s) configured."
        listItems={host.servers.configured}
        renderListItem={renderServer}
      />
    ),
    [host.servers.configured, renderServer],
  );

  const syncingList = useMemo(
    () => (
      <List
        header="Syncing"
        listEmpty="No server(s) syncing."
        listItems={host.servers.replicating}
        renderListItem={renderServer}
      />
    ),
    [host.servers.replicating, renderServer],
  );

  const runningList = useMemo(
    () => (
      <List
        header="Running"
        listEmpty="No server(s) running."
        listItems={host.servers.running}
        renderListItem={renderServer}
      />
    ),
    [host.servers.running, renderServer],
  );

  return (
    <MuiGrid
      container
      spacing="1em"
      sx={{
        width: '100%',

        [`& > .${muiGridClasses.root}`]: {
          width: {
            xs: '100%',
            lg: '50%',
            xl: 'calc(100% / 3)',
          },
        },
      }}
    >
      <MuiGrid>{configuredList}</MuiGrid>
      <MuiGrid>{syncingList}</MuiGrid>
      <MuiGrid>{runningList}</MuiGrid>
    </MuiGrid>
  );
};

export default HostServerList;
