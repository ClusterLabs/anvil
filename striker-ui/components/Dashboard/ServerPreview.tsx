import Grid from '@mui/material/Grid';
import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import {
  Preview,
  PreviewBox as BasePreviewBox,
  PreviewFrame,
} from '../Display';
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

type ServerPreviewProps = {
  server: APIServerOverview;
};

const ServerPreview: React.FC<ServerPreviewProps> = (props) => {
  const { server } = props;

  const showControls = useMemo<boolean>(() => {
    if (server.jobs) {
      const jobs = Object.values(server.jobs);

      return jobs.every((job) => job.progress === 100);
    }

    return true;
  }, [server.jobs]);

  return (
    <Grid item>
      <PreviewFrame<APIServerOverview>
        getHeader={({ jobs, name }) => {
          if (jobs) {
            return <BodyText noWrap>{name}</BodyText>;
          }

          return (
            <Link href={`/server?name=${name}`} noWrap>
              {name}
            </Link>
          );
        }}
        key={`${server.uuid}-preview`}
        server={server}
        showControls={showControls}
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
};

export default ServerPreview;
