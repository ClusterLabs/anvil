import { Menu, MenuItem } from '@mui/material';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import FlexBox from './FlexBox';
import List from './List';
import periodicFetch from '../lib/fetchers/periodicFetch';
import PieProgress from './PieProgress';
import { BodyText } from './Text';
import { elapsed, now } from '../lib/time';

type JobSummaryOptionalPropsWithDefault = {
  getJobUrl?: (epoch: number) => string;
  openInitially?: boolean;
  refreshInterval?: number;
};

type JobSummaryOptionalPropsWithoutDefault = {
  onFetchSuccessAppend?: (data: APIJobOverviewList) => void;
};

type JobSummaryOptionalProps = JobSummaryOptionalPropsWithDefault &
  JobSummaryOptionalPropsWithoutDefault;

type JobSummaryProps = JobSummaryOptionalProps;

type JobSummaryForwardedRefContent = {
  setAnchor?: (element: HTMLElement | undefined) => void;
  setOpen?: (value: boolean) => void;
};

const JOB_LIST_LENGTH = '20em';
const JOB_SUMMARY_DEFAULT_PROPS: Required<JobSummaryOptionalPropsWithDefault> &
  JobSummaryOptionalPropsWithoutDefault = {
  // TODO: remove after debug
  getJobUrl: () => `${API_BASE_URL}/job?start=0`,
  // getJobUrl: (epoch) => `${API_BASE_URL}/job?start=${epoch}`,
  onFetchSuccessAppend: undefined,
  openInitially: false,
  refreshInterval: 10000,
};

const JobSummary = forwardRef<JobSummaryForwardedRefContent, JobSummaryProps>(
  (
    {
      getJobUrl = JOB_SUMMARY_DEFAULT_PROPS.getJobUrl,
      onFetchSuccessAppend,
      openInitially = JOB_SUMMARY_DEFAULT_PROPS.openInitially,
      refreshInterval = JOB_SUMMARY_DEFAULT_PROPS.refreshInterval,
    },
    ref,
  ) => {
    const [jobs, setJobs] = useState<APIJobOverviewList>({});
    const [isOpenJobSummary, setIsOpenJobSummary] =
      useState<boolean>(openInitially);
    const [menuAnchorElement, setMenuAnchorElement] = useState<
      HTMLElement | undefined
    >();

    // Epoch in seconds
    const loaded = useMemo(() => now(), []);
    const nao = now();

    periodicFetch<APIJobOverviewList>(getJobUrl(loaded), {
      onError: () => {
        setJobs({});
      },
      onSuccess: (rawAnvilJobs) => {
        setJobs(rawAnvilJobs);

        onFetchSuccessAppend?.call(null, rawAnvilJobs);
      },
      refreshInterval,
    });

    useImperativeHandle(
      ref,
      () => ({
        setAnchor: (value) => setMenuAnchorElement(value),
        setOpen: (value) => setIsOpenJobSummary(value),
      }),
      [],
    );

    const jobList = useMemo(
      () => (
        <FlexBox>
          <List
            scroll
            listEmpty="No currently running and recently completed jobs."
            listItems={jobs}
            listProps={{
              sx: { maxHeight: JOB_LIST_LENGTH, width: JOB_LIST_LENGTH },
            }}
            renderListItem={(jobUuid, job) => {
              const { host, name, progress, started, title } = job;
              const { shortName: shortHostName } = host;
              const label = title || name;

              let status: string;

              if (started) {
                const { unit, value } = elapsed(nao - started);

                status = `Started ~${value}${unit} ago on ${shortHostName}.`;
              } else {
                status = `Queued on ${shortHostName}`;
              }

              return (
                <MenuItem sx={{ width: '100%' }}>
                  <FlexBox fullWidth spacing=".2em">
                    <FlexBox row spacing=".5em">
                      <PieProgress sx={{ flexShrink: 0 }} value={progress} />
                      <BodyText
                        sx={{
                          overflowX: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {label}
                      </BodyText>
                    </FlexBox>
                    <BodyText>{status}</BodyText>
                  </FlexBox>
                </MenuItem>
              );
            }}
          />
        </FlexBox>
      ),
      [jobs, nao],
    );

    return (
      <Menu
        anchorEl={menuAnchorElement}
        onClose={() => {
          setIsOpenJobSummary(false);
          setMenuAnchorElement(undefined);
        }}
        open={isOpenJobSummary}
        variant="menu"
      >
        {jobList}
      </Menu>
    );
  },
);

JobSummary.defaultProps = JOB_SUMMARY_DEFAULT_PROPS;
JobSummary.displayName = 'JobSummary';

export type { JobSummaryForwardedRefContent, JobSummaryProps };

export default JobSummary;
