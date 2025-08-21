import Grid from '@mui/material/Grid';
import { useRouter } from 'next/router';
import { useMemo, useRef } from 'react';

import { ProgressBar } from '../Bars';
import FlexBox from '../FlexBox';
import Link from '../Link';
import { InnerPanel, InnerPanelBody, InnerPanelHeader, Panel } from '../Panels';
import Pre from '../Pre';
import ScrollBox from '../ScrollBox';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';
import useJobStatus from '../../hooks/useJobStatus';
import useScrollHelpers from '../../hooks/useScrollHelpers';

const CenterPanel: React.FC<React.PropsWithChildren> = (props) => {
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

const StrikerInitProgress: React.FC<StrikerInitProgressProps> = (props) => {
  const { ipRef, jobUuid, reinit } = props;

  const router = useRouter();

  const fetchErrorConsecutiveCount = useRef<number>(0);

  const redirectTimeout = useRef<NodeJS.Timeout | null>(null);

  const confirm = useConfirmDialog();

  const redirectParams = useMemo<{ label: string; path: string }>(() => {
    let label = 'login';
    let path = '/login';

    if (reinit) {
      label = 'striker config';
      path = '/config';
    }

    if (ipRef?.current) {
      label += ` (at ${ipRef.current})`;
    }

    return { label, path };
  }, [ipRef, reinit]);

  const scroll = useScrollHelpers<HTMLDivElement>({
    follow: true,
  });

  const { data: initJob } = useFetch<APIJobDetail>(`/init/job/${jobUuid}`, {
    onError: () => {
      fetchErrorConsecutiveCount.current += 1;

      if (ipRef?.current && fetchErrorConsecutiveCount.current > 2) {
        confirm.setConfirmDialogProps({
          actionProceedText: `Try to redirect`,
          actionCancelText: `Change URL manually`,
          content: (
            <FlexBox>
              <BodyText>
                Lost connection to the striker, which will happen if you changed
                its IFN IP address.
              </BodyText>
              <BodyText>
                You can try the auto-redirect option, which will fail if
                you&apos;re taking additional steps in connecting, i.e., port
                fowarding. Otherwise, please manually change the URL in your
                browser accordingly.
              </BodyText>
            </FlexBox>
          ),
          onProceedAppend: () => {
            confirm.setConfirmDialogLoading(true);

            router.replace(`http://${ipRef.current}${redirectParams.path}`);
          },
          titleText: `Lost connection, try redirecting to ${redirectParams.label}?`,
        });

        confirm.setConfirmDialogOpen(true);
      }
    },
    onSuccess: (data) => {
      fetchErrorConsecutiveCount.current = 0;

      const { progress } = data;

      if (redirectTimeout.current === null && progress === 100) {
        redirectTimeout.current = setTimeout(
          (url: string) => {
            router.replace(url);
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
      {confirm.confirmDialog}
    </CenterPanel>
  );
};

export default StrikerInitProgress;
