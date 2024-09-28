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

const CenterPanel: FC = (props) => {
  const { children } = props;

  return (
    <Panel
      sx={{
        marginLeft: { xs: '1em', sm: 'auto' },
        marginRight: { xs: '1em', sm: 'auto' },
        marginTop: 'calc(50vh - 10em)',
        maxWidth: { xs: undefined, sm: '60%', md: '50%', lg: '40%' },
        minWidth: 'fit-content',
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

  const { data: initJob } = useFetch<APIJobDetail>(`/job/${jobUuid}`, {
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

  const statusList = useMemo(() => {
    if (!initJob?.status) return <Pre>Loading...</Pre>;

    const { status } = initJob;

    const content = Object.values(status)
      .reduce<string>((previous, entry) => `${previous}${entry.value}\n\n`, '')
      .trimEnd();

    return <Pre>{content}</Pre>;
  }, [initJob]);

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
              <ScrollBox id="status-scroll-box" height="20vh">
                {statusList}
              </ScrollBox>
            </InnerPanelBody>
          </InnerPanel>
        </Grid>
      </Grid>
    </CenterPanel>
  );
};

export default StrikerInitProgress;
