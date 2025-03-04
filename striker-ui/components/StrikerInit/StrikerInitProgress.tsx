import { Grid } from '@mui/material';
import { FC, useMemo, useRef } from 'react';

import { ProgressBar } from '../Bars';
import Link from '../Link';
import { InnerPanel, InnerPanelBody, InnerPanelHeader, Panel } from '../Panels';
import Pre from '../Pre';
import ScrollBox from '../ScrollBox';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useFetch from '../../hooks/useFetch';
import useJobStatus from '../../hooks/useJobStatus';
import useScrollHelpers from '../../hooks/useScrollHelpers';

const CenterPanel: FC = (props) => {
  const { children } = props;

  return (
    <Panel
      sx={{
        marginLeft: { xs: '1em', sm: 'auto' },
        marginRight: { xs: '1em', sm: 'auto' },
        // Half screen - half status area - text & progress bar (roughly)
        marginTop: 'calc(50vh - 30vh - 6em)',
        width: {
          xs: undefined,
          sm: '90vw',
          md: '80vw',
          lg: '70vw',
          xl: '60vw',
        },
      }}
    >
      {children}
    </Panel>
  );
};

const StrikerInitProgress: FC<StrikerInitProgressProps> = (props) => {
  const { jobUuid, reinit } = props;

  const redirectTimeout = useRef<number | null>(null);

  const redirectParams = useMemo<{ label: string; path: string }>(() => {
    let label = 'login';
    let path = '/login';

    if (reinit) {
      label = 'striker config';
      path = '/config';
    }

    return { label, path };
  }, [reinit]);

  const scroll = useScrollHelpers<HTMLDivElement>({
    follow: true,
  });

  const { data: initJob } = useFetch<APIJobDetail>(`/init/job/${jobUuid}`, {
    onSuccess: (data) => {
      const { progress } = data;

      if (redirectTimeout.current === null && progress === 100) {
        redirectTimeout.current = setTimeout(
          (url: string) => {
            window.location.replace(url);
          },
          3000,
          redirectParams.path,
        );
      }
    },
    refreshInterval: 2000,
  });

  const status = useJobStatus(initJob?.status);

  if (!initJob) {
    return (
      <CenterPanel>
        <Spinner mt={0} />
      </CenterPanel>
    );
  }

  return (
    <CenterPanel>
      <Grid columns={1} container rowGap=".6em">
        <Grid item width="100%">
          <BodyText>
            You will be auto redirected to {redirectParams.label} after
            initialization completes. If not, you can manually access{' '}
            <Link display="inline-flex" href={redirectParams.path}>
              {redirectParams.label}
            </Link>{' '}
            after completion.
          </BodyText>
        </Grid>
        <Grid item width="100%">
          <ProgressBar progressPercentage={initJob.progress} />
        </Grid>
        <Grid item width="100%">
          <InnerPanel mb={0} mt={0}>
            <InnerPanelHeader>
              <BodyText>Status</BodyText>
            </InnerPanelHeader>
            <InnerPanelBody>
              <ScrollBox
                height="60vh"
                key="status"
                lineHeight="2"
                ref={scroll.callbackRef}
              >
                <Pre>{status.string}</Pre>
              </ScrollBox>
            </InnerPanelBody>
          </InnerPanel>
        </Grid>
      </Grid>
    </CenterPanel>
  );
};

export default StrikerInitProgress;
