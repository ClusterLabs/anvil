import MuiBox from '@mui/material/Box';
import muiCircularProgressClasses from '@mui/material/CircularProgress/circularProgressClasses';
import Grid from '@mui/material/Grid';
import styled from '@mui/material/styles/styled';
import capitalize from 'lodash/capitalize';
import { useMemo } from 'react';

import { BORDER_RADIUS } from '../../lib/consts/DEFAULT_THEME';
import SERVER from '../../lib/consts/SERVER';

import Decorator, { Colours } from '../Decorator';
import { Preview, PreviewBox as BasePreviewBox } from '../Display';
import Link from '../Link';
import PieProgress from '../PieProgress';
import ServerMenu from '../ManageServer/ServerMenu';
import { BodyText } from '../Text';

const MAP_TO_DECORATOR_COLOUR: Record<string, Colours> = {
  running: 'ok',
  'shut off': 'off',
  crashed: 'error',
};

const PreviewBox = styled(BasePreviewBox)(() => {
  const width = '3em';

  return {
    borderRadius: BORDER_RADIUS,
    height: `calc(${width} * 0.8)`,
    width,
  };
});

const BlockingJobsProgressBox = styled(BasePreviewBox)(() => {
  const width = '3.2em';

  return {
    height: width,
    margin: 0,
    width,
  };
});

const getDecoratorColour = (state: string): Colours =>
  MAP_TO_DECORATOR_COLOUR[state] ?? 'warning';

const ServerSummary: React.FC<ServerListItemProps> = (props) => {
  const { servers, uuid: serverUuid } = props;

  const server = servers[serverUuid];

  const blocking = useMemo(
    () => SERVER.states.blocking.includes(server.state),
    [server.state],
  );

  const blockingJobsProgress = useMemo(() => {
    if (!server.jobs) {
      return undefined;
    }

    return (
      <BlockingJobsProgressBox>
        {Object.values(server.jobs).map((job, index) => {
          const { peer, progress, uuid } = job;

          const size = `calc(2.8em - ${1.5 * index}em)`;

          return (
            <PieProgress
              key={`${uuid}-progress`}
              slotProps={{
                box: {
                  sx: {
                    position: 'absolute',
                  },
                },
                pie: {
                  size,
                  sx: {
                    opacity: peer ? 0.6 : undefined,

                    [`& .${muiCircularProgressClasses.circle}`]: {
                      strokeLinecap: 'round',
                    },
                  },
                  thickness: 6,
                },
                underline: {
                  thickness: progress ? 0 : 1,
                },
              }}
              value={progress}
            />
          );
        })}
      </BlockingJobsProgressBox>
    );
  }, [server.jobs]);

  let decorator: React.ReactNode;
  let preview: React.ReactNode;
  let serverName: React.ReactNode;
  let serverState: React.ReactNode;

  if (blocking) {
    decorator = <Grid item>{blockingJobsProgress}</Grid>;

    serverName = <BodyText noWrap>{server.name}</BodyText>;

    serverState = <BodyText noWrap>{capitalize(server.state)}...</BodyText>;
  } else {
    decorator = (
      <Grid alignSelf="stretch" item>
        <Decorator colour={getDecoratorColour(server.state)} />
      </Grid>
    );

    preview = (
      <Preview
        server={server}
        slots={{
          screenshotBox: <PreviewBox />,
        }}
        slotProps={{
          screenshot: {
            sx: {
              fontSize: '.6em',
            },
          },
        }}
      />
    );

    serverName = (
      <Link href={`/server?name=${server.name}`} noWrap>
        {server.name}
      </Link>
    );

    serverState = <BodyText noWrap>{capitalize(server.state)}</BodyText>;
  }

  return (
    <Grid alignItems="center" container spacing="0.5em">
      {decorator}
      <Grid item>{preview}</Grid>
      <Grid item xs>
        <Grid container>
          <Grid item width="100%">
            {serverName}
          </Grid>
          <Grid item width="100%">
            {serverState}
          </Grid>
        </Grid>
      </Grid>
      <Grid item xs>
        <MuiBox>
          <Link href={`/anvil?name=${server.anvil.name}`} noWrap>
            {server.anvil.name}
          </Link>
          {server.host && <BodyText noWrap>{server.host.short}</BodyText>}
        </MuiBox>
      </Grid>
      <Grid item>
        <ServerMenu
          node={server.anvil}
          server={server}
          slotProps={{
            button: {
              slotProps: {
                button: {
                  icon: {
                    size: 'small',
                  },
                },
              },
            },
          }}
        />
      </Grid>
    </Grid>
  );
};

export default ServerSummary;
