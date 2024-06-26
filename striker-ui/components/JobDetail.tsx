import { Grid, useMediaQuery, useTheme } from '@mui/material';
import { FC, useMemo } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';
import { REP_LABEL_PASSW } from '../lib/consts/REG_EXP_PATTERNS';

import { ProgressBar } from './Bars';
import { DialogScrollBox } from './Dialog';
import FlexBox from './FlexBox';
import IconButton from './IconButton';
import pad from '../lib/pad';
import {
  ExpandablePanel,
  InnerPanel,
  InnerPanelBody,
  InnerPanelHeader,
} from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { BodyText, SensitiveText, SmallText } from './Text';
import { ago, now } from '../lib/time';

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
  const { refreshInterval = 10000, uuid } = props;

  const theme = useTheme();
  const breakpointSmall = useMediaQuery(theme.breakpoints.up('sm'));

  const { data: job } = periodicFetch<APIJobDetail>(
    `${API_BASE_URL}/job/${uuid}`,
    {
      onError: () => {
        // Show error message
      },
      refreshInterval,
    },
  );

  const nao = now();

  const dataList = useMemo(
    () =>
      job &&
      Object.entries(job.data).map((entry) => {
        const [id, data] = entry;
        const key = `data-${id}`;

        const value = REP_LABEL_PASSW.test(data.name) ? (
          <SensitiveText monospaced>{data.value}</SensitiveText>
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

  const statusList = useMemo(
    () =>
      job &&
      Object.entries(job.status).map((entry) => {
        const [id, status] = entry;
        const key = `status-${id}`;

        return (
          <Grid columnGap=".2em" container item key={key}>
            <Grid item>
              <SmallText monospaced>&gt;</SmallText>
            </Grid>
            <Grid item xs>
              <SmallText monospaced>{status.value}</SmallText>
            </Grid>
          </Grid>
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

  return job ? (
    <DialogScrollBox>
      <Grid columns={1} container rowGap=".6em">
        <Grid item width="100%">
          <BodyText>{job.title}</BodyText>
        </Grid>
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
              ~{startedAgo} ago{breakpointSmall && ` (${startedReadable})`}
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
        {dataList?.length && (
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
                sx={{ '& > *': { width: 'max-content' } }}
              >
                {dataList}
              </FlexBox>
            </ExpandablePanel>
          </Grid>
        )}
        <Grid item width="100%">
          <InnerPanel mb={0} mt={0}>
            <InnerPanelHeader>
              <BodyText>Status</BodyText>
            </InnerPanelHeader>
            <InnerPanelBody>
              <Grid container>{statusList}</Grid>
            </InnerPanelBody>
          </InnerPanel>
        </Grid>
      </Grid>
    </DialogScrollBox>
  ) : (
    <Spinner />
  );
};

export default JobDetail;
