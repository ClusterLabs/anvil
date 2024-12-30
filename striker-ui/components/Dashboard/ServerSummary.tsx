import { Grid } from '@mui/material';
import { capitalize } from 'lodash';
import { useMemo } from 'react';

import Decorator, { Colours } from '../Decorator';
import Divider from '../Divider';
import Link from '../Link';
import ServerMenu from '../ServerMenu';
import { BodyText } from '../Text';

const MAP_TO_DECORATOR_COLOUR: Record<string, Colours> = {
  running: 'ok',
  'shut off': 'off',
  crashed: 'error',
};

const getDecoratorColour = (state: string): Colours =>
  MAP_TO_DECORATOR_COLOUR[state] ?? 'warning';

const ServerSummary: React.FC<ServerListItemProps> = (props) => {
  const { anvils, servers, uuid: serverUuid } = props;

  const server = servers[serverUuid];
  const anvil = anvils[server.anvil.uuid];

  const hostValues = useMemo(() => Object.values(anvil.hosts), [anvil.hosts]);

  return (
    <Grid container spacing="1em">
      <Grid item>
        <Decorator colour={getDecoratorColour(server.state)} />
      </Grid>
      <Grid item>
        <Grid container width="14em">
          <Grid item width="100%">
            <Link href={`/server?name=${server.name}`}>{server.name}</Link>
          </Grid>
          <Grid item width="100%">
            <BodyText>{capitalize(server.state)}</BodyText>
          </Grid>
        </Grid>
      </Grid>
      <Grid item xs>
        <Grid container>
          <Grid item width="100%">
            <Link href={`/anvil?anvil_uuid=${server.anvil.uuid}`} noWrap>
              {server.anvil.name}
            </Link>
          </Grid>
          <Grid item width="100%">
            <Grid container columnSpacing="0.5em">
              {...hostValues.reduce<React.ReactNode[]>(
                (previous, host, index, array) => {
                  const on = host.uuid === server.host?.uuid;

                  previous.push(
                    <Grid item key={`${host.uuid}`}>
                      <BodyText noWrap selected={on}>
                        {host.short}
                      </BodyText>
                    </Grid>,
                  );

                  if (index + 1 < array.length) {
                    previous.push(
                      <Grid item key={`${host.uuid}-end`}>
                        <Divider orientation="vertical" />
                      </Grid>,
                    );
                  }

                  return previous;
                },
                [],
              )}
            </Grid>
          </Grid>
        </Grid>
      </Grid>
      <Grid alignSelf="center" item>
        <ServerMenu
          iconButtonProps={{ size: 'small' }}
          serverName={server.name}
          serverState={server.state}
          serverUuid={server.uuid}
        />
      </Grid>
    </Grid>
  );
};

export default ServerSummary;
