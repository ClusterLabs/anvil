import { Breakpoint, Grid, styled } from '@mui/material';

import {
  Preview,
  PreviewBox as BasePreviewBox,
  PreviewFrame,
} from '../Display';
import Divider from '../Divider';
import Link from '../Link';
import { BodyText } from '../Text';

const PreviewBox = styled(BasePreviewBox)(({ theme }) => {
  const widths: Partial<Record<Breakpoint, string>> = {
    xs: 'calc(100vw - 4.88em)',
    sm: 'calc(50vw - 3.1em)',
    md: 'calc(100vw / 3 - 2.52em)',
    lg: 'calc(25vw - 2.22em)',
    xl: '10vw',
  };

  const getHeight = (width = '0') => `calc(${width} * 0.8)`;

  return {
    [theme.breakpoints.up('xs')]: {
      height: getHeight(widths.xs),
      width: widths.xs,
    },

    [theme.breakpoints.up('sm')]: {
      height: getHeight(widths.sm),
      width: widths.sm,
    },

    [theme.breakpoints.up('md')]: {
      height: getHeight(widths.md),
      width: widths.md,
    },

    [theme.breakpoints.up('lg')]: {
      height: getHeight(widths.lg),
      width: widths.lg,
    },
  };
});

const buildPreview = (server: APIServerOverview): React.ReactNode => (
  <Grid item>
    <PreviewFrame<APIServerOverview>
      getHeader={({ anvil, jobs, name }) => (
        <>
          {jobs ? (
            <BodyText noWrap>{name}</BodyText>
          ) : (
            <Link href={`/server?name=${name}`} noWrap>
              {name}
            </Link>
          )}
          <Link
            href={`/anvil?anvil_uuid=${anvil.uuid}`}
            noWrap
            sx={{ opacity: 0.7 }}
          >
            {anvil.name}
          </Link>
        </>
      )}
      key={`${server.uuid}-preview`}
      server={server}
      showControls={!server.jobs}
    >
      <Preview
        server={server}
        slots={{
          screenshotBox: <PreviewBox />,
        }}
      />
    </PreviewFrame>
  </Grid>
);

const ServerPanels: React.FC<ServerPanelsProps> = (props) => {
  const { groups, servers } = props;

  return (
    <Grid container spacing="1em">
      {groups.match.map((uuid) => buildPreview(servers[uuid]))}
      {groups.match.length > 0 && (
        <Grid item width="100%">
          <Divider flexItem orientation="horizontal" />
        </Grid>
      )}
      {groups.none.map((uuid) => buildPreview(servers[uuid]))}
    </Grid>
  );
};

export default ServerPanels;
