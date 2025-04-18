import { Grid, useMediaQuery, useTheme } from '@mui/material';
import {
  FC,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import { REP_LABEL_PASSW } from '../lib/consts/REG_EXP_PATTERNS';

import { ProgressBar } from './Bars';
import { DialogScrollBox, DialogWithHeaderContext } from './Dialog';
import FlexBox from './FlexBox';
import IconButton from './IconButton';
import MessageBox, { Message } from './MessageBox';
import pad from '../lib/pad';
import {
  ExpandablePanel,
  InnerPanel,
  InnerPanelBody,
  InnerPanelHeader,
} from './Panels';
import Pre from './Pre';
import ScrollBox from './ScrollBox';
import Spinner from './Spinner';
import SyncIndicator from './SyncIndicator';
import { BodyText, HeaderText, SensitiveText, SmallText } from './Text';
import { ago, now } from '../lib/time';
import useFetch from '../hooks/useFetch';
import useJobStatus from '../hooks/useJobStatus';
import useScrollHelpers from '../hooks/useScrollHelpers';

const toReadableTimestamp = (seconds: number): string => {
  const milliseconds = seconds * 1000;

  const target = new Date(milliseconds);

  const month = target.getMonth() + 1;
  const date = target.getDate();

  const h = target.getHours();
  const m = target.getMinutes();
  const s = target.getSeconds();

  return `${pad(month)}-${pad(date)}, ${pad(h)}:${pad(m)}:${pad(s)}`;
};

const JobDetail: FC<JobDetailProps> = (props) => {
  const { refreshInterval, uuid } = props;

  const theme = useTheme();
  const breakpointSmall = useMediaQuery(theme.breakpoints.up('sm'));

  const dialog = useContext(DialogWithHeaderContext);

  const [apiMessage, setApiMessage] = useState<Message>({
    children: `Job ${uuid} details unavailable`,
    type: 'warning',
  });

  const {
    data: job,
    loading: loadingJob,
    validating: validatingJob,
  } = useFetch<APIJobDetail>(`/job/${uuid}`, {
    onError: (error) => {
      setApiMessage({
        children: `Failed to get job ${uuid} details. Error: ${error}`,
        type: 'error',
      });
    },
    onSuccess: (data) => {
      dialog?.setHeader(data.title);
    },
    periodic: true,
    refreshInterval,
  });

  const clearDialogHeader = useCallback(() => {
    dialog?.setHeader('');
  }, [dialog]);

  useEffect(() => {
    if (!(dialog && job)) {
      return clearDialogHeader;
    }

    dialog.setHeader(
      <>
        <HeaderText>{job.title}</HeaderText>
        <SyncIndicator syncing={validatingJob} />
      </>,
    );

    return clearDialogHeader;
  }, [clearDialogHeader, dialog, job, validatingJob]);

  const status = useJobStatus(job?.status);

  const nao = now();

  const dataList = useMemo(
    () =>
      job &&
      Object.entries(job.data).map((entry) => {
        const [id, data] = entry;
        const key = `data-${id}`;

        const value =
          REP_LABEL_PASSW.test(data.name) && data.value.length > 0 ? (
            <SensitiveText>{data.value}</SensitiveText>
          ) : (
            data.value
          );

        return (
          <SmallText key={key} monospaced noWrap textOverflow="initial">
            {data.name}={value}
          </SmallText>
        );
      }),
    [job],
  );

  const startedReadable = useMemo(
    () => job && toReadableTimestamp(job.started),
    [job],
  );

  const modifiedReadable = useMemo(
    () => job && toReadableTimestamp(job.modified),
    [job],
  );

  const startedAgo = useMemo(() => job && ago(nao - job.started), [job, nao]);

  const modifiedAgo = useMemo(() => job && ago(nao - job.modified), [job, nao]);

  const started = useMemo(() => {
    if (!job) {
      return undefined;
    }

    if (!job.started) {
      return <>Not started</>;
    }

    return (
      <>
        ~{startedAgo} ago{breakpointSmall && ` (${startedReadable})`}
      </>
    );
  }, [breakpointSmall, job, startedAgo, startedReadable]);

  const scroll = useScrollHelpers<HTMLDivElement>({
    follow: true,
  });

  if (loadingJob) {
    return <Spinner mt={0} />;
  }

  if (!job) {
    return <MessageBox {...apiMessage} />;
  }

  return (
    <DialogScrollBox>
      <Grid columns={1} container rowGap=".6em">
        <Grid item width="100%">
          <ProgressBar progressPercentage={job.progress} />
        </Grid>
        <Grid item width="100%">
          <BodyText>{job.description}</BodyText>
        </Grid>
        <Grid columns={2} container item>
          <Grid item xs={1}>
            <BodyText>Host</BodyText>
          </Grid>
          <Grid item xs={1}>
            <SmallText monospaced noWrap textAlign="end">
              {breakpointSmall ? job.host.name : job.host.shortName}
            </SmallText>
          </Grid>
          <Grid item xs={1}>
            <BodyText>PID</BodyText>
          </Grid>
          <Grid item xs={1}>
            <SmallText monospaced noWrap textAlign="end">
              {job.pid}
            </SmallText>
          </Grid>
          <Grid item xs={1}>
            <BodyText>Started</BodyText>
          </Grid>
          <Grid item xs={1}>
            <BodyText noWrap textAlign="end">
              {started}
            </BodyText>
          </Grid>
          <Grid item xs={1}>
            <BodyText>Last updated</BodyText>
          </Grid>
          <Grid item xs={1}>
            <BodyText noWrap textAlign="end">
              ~{modifiedAgo} ago{breakpointSmall && ` (${modifiedReadable})`}
            </BodyText>
          </Grid>
        </Grid>
        <Grid item width="100%">
          <InnerPanel mb={0} mt={0}>
            <InnerPanelHeader>
              <BodyText>Status</BodyText>
            </InnerPanelHeader>
            <InnerPanelBody>
              <ScrollBox
                height="24vh"
                key="job-status"
                lineHeight="2"
                ref={scroll.callbackRef}
              >
                <Pre>{status.string}</Pre>
              </ScrollBox>
            </InnerPanelBody>
          </InnerPanel>
        </Grid>
        <Grid item width="100%">
          <ExpandablePanel
            header={
              <FlexBox fullWidth growFirst row>
                <BodyText>Command</BodyText>
                <IconButton
                  iconProps={{ fontSize: 'small' }}
                  mapPreset="copy"
                  onClick={() => navigator.clipboard.writeText(job.command)}
                  size="small"
                />
              </FlexBox>
            }
            panelProps={{ mb: 0, mt: 0 }}
          >
            <FlexBox overflow="scroll" paddingBottom=".8em">
              <SmallText
                monospaced
                noWrap
                textOverflow="initial"
                width="max-content"
              >
                {job.command}
              </SmallText>
            </FlexBox>
          </ExpandablePanel>
        </Grid>
        <Grid item width="100%">
          <ExpandablePanel
            header={
              <FlexBox fullWidth growFirst row>
                <BodyText>Data</BodyText>
                <IconButton
                  iconProps={{ fontSize: 'small' }}
                  mapPreset="copy"
                  onClick={() => {
                    const data = Object.values(job.data).reduce<string>(
                      (previous, { name, value }) =>
                        `${previous}${name}=${value}\n`,
                      '',
                    );

                    navigator.clipboard.writeText(data);
                  }}
                  size="small"
                />
              </FlexBox>
            }
            panelProps={{ mb: 0, mt: 0 }}
          >
            <FlexBox
              overflow="scroll"
              paddingBottom=".8em"
              spacing=".2em"
              sx={{
                '& > *': {
                  width: 'max-content',
                },
              }}
            >
              {dataList}
            </FlexBox>
          </ExpandablePanel>
        </Grid>
      </Grid>
    </DialogScrollBox>
  );
};

export default JobDetail;
