import { Grid, styled } from '@mui/material';
import { useMemo } from 'react';

import {
  Preview,
  PreviewBox as BasePreviewBox,
  PreviewFrame,
} from '../Display';
import Divider from '../Divider';
import Link from '../Link';
import { BodyText } from '../Text';

const PreviewBox = styled(BasePreviewBox)(({ theme }) => {
  const getHeight = (width = '0') => `calc(${width} * 0.6)`;

  return {
    width: '100%',

    [theme.breakpoints.up('xs')]: {
      height: getHeight('100vw'),
    },

    [theme.breakpoints.up('sm')]: {
      height: getHeight('50vw'),
    },

    [theme.breakpoints.up('md')]: {
      height: getHeight('100vw / 3'),
    },

    [theme.breakpoints.up('lg')]: {
      height: getHeight('25vw'),
    },

    [theme.breakpoints.up('xl')]: {
      height: getHeight('100vw / 6'),
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
          <Link href={`/anvil?name=${anvil.name}`} noWrap sx={{ opacity: 0.7 }}>
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

  const panels = useMemo<React.ReactNode[]>(() => {
    const groupEntries = Object.entries(groups);

    return groupEntries.reduce<React.ReactNode[]>(
      (elements, [groupName, group], groupIndex, array) => {
        if (!group.length) {
          return elements;
        }

        group.forEach((uuid) => {
          const server = servers[uuid];

          elements.push(
            <Grid key={`${uuid}-panel`} item xs={1}>
              {buildPreview(server)}
            </Grid>,
          );
        });

        const last = groupIndex + 1 === array.length;

        if (!last) {
          elements.push(
            <Grid key={`${groupName}-end`} item width="100%">
              <Divider orientation="horizontal" />
            </Grid>,
          );
        }

        return elements;
      },
      [],
    );
  }, [groups, servers]);

  return (
    <Grid
      columns={{
        xs: 1,
        sm: 2,
        md: 3,
        lg: 4,
        xl: 6,
      }}
      container
      spacing="1em"
    >
      {panels}
    </Grid>
  );
};

export default ServerPanels;
