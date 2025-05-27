import { Grid, gridClasses } from '@mui/material';
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
        <Grid alignItems="center" columnSpacing="1em" container width="100%">
          <Grid item>
            <Link href={`/server?name=${name}`} noWrap>
              {name}
            </Link>
          </Grid>
          <Grid
            item
            sx={{
              [`& > .${gridClasses.container}`]: {
                alignItems: 'center',
                width: '100%',

                [`& > .${gridClasses.item}:nth-child(odd)`]: {
                  width: '5em',
                },
              },
            }}
            xs
          >
            <Grid columnSpacing="0.5em" container>
              <Grid item>
                <BodyText>Connection</BodyText>
              </Grid>
              <Grid item xs>
                <MonoText>{resource.connection.state}</MonoText>
              </Grid>
            </Grid>
            <Grid columnSpacing="0.5em" container>
              <Grid item>
                <BodyText>Disk</BodyText>
              </Grid>
              <Grid item xs>
                <MonoText>{resource.replication.state}</MonoText>
              </Grid>
            </Grid>
          </Grid>
        </Grid>
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
    <Grid
      container
      spacing="1em"
      sx={{
        [`& > .${gridClasses.item}`]: {
          width: {
            xs: '100%',
            lg: '50%',
            xl: 'calc(100% / 3)',
          },
        },
      }}
    >
      <Grid item>{configuredList}</Grid>
      <Grid item>{syncingList}</Grid>
      <Grid item>{runningList}</Grid>
    </Grid>
  );
};

export default HostServerList;
