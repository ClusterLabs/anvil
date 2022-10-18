import { Menu } from '@mui/material';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import { ProgressBar } from './Bars';
import FlexBox from './FlexBox';
import Link from './Link';
import List from './List';
import periodicFetch from '../lib/fetchers/periodicFetch';
import { BodyText } from './Text';
import useProtect from '../hooks/useProtect';
import useProtectedState from '../hooks/useProtectedState';

type AnvilJobs = {
  [jobUUID: string]: {
    jobCommand: string;
    jobName: string;
    jobProgress: number;
    jobUUID: string;
  };
};

type JobSummaryOptionalPropsWithDefault = {
  openInitially?: boolean;
};

type JobSummaryOptionalPropsWithoutDefault = {
  onFetchSuccessAppend?: (data: AnvilJobs) => void;
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
  onFetchSuccessAppend: undefined,
  openInitially: false,
};

const JobSummary = forwardRef<JobSummaryForwardedRefContent, JobSummaryProps>(
  (
    {
      onFetchSuccessAppend,
      openInitially = JOB_SUMMARY_DEFAULT_PROPS.openInitially,
    },
    ref,
  ) => {
    const { protect } = useProtect();

    const [anvilJobs, setAnvilJobs] = useProtectedState<AnvilJobs>({}, protect);
    const [isOpenJobSummary, setIsOpenJobSummary] =
      useState<boolean>(openInitially);
    const [menuAnchorElement, setMenuAnchorElement] = useState<
      HTMLElement | undefined
    >();

    periodicFetch<AnvilJobs>(`${API_BASE_URL}/job`, {
      onError: () => {
        setAnvilJobs({});
      },
      onSuccess: (rawAnvilJobs) => {
        setAnvilJobs(rawAnvilJobs);

        onFetchSuccessAppend?.call(null, rawAnvilJobs);
      },
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
            listItems={anvilJobs}
            listProps={{
              sx: { maxHeight: JOB_LIST_LENGTH, width: JOB_LIST_LENGTH },
            }}
            renderListItem={(jobUUID, { jobName, jobProgress }) => (
              <FlexBox sm="row" sx={{ width: '97%' }} xs="column">
                <FlexBox spacing={0} sx={{ width: 'inherit' }}>
                  <BodyText
                    sx={{
                      overflowX: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {jobName}
                  </BodyText>
                  <ProgressBar progressPercentage={jobProgress} />
                </FlexBox>
              </FlexBox>
            )}
          />
          <Link href="cgi-bin/striker?jobs=true">More details</Link>
        </FlexBox>
      ),
      [anvilJobs],
    );
    const jobSummary = useMemo(
      () => (
        <Menu
          anchorEl={menuAnchorElement}
          MenuListProps={{ sx: { padding: '.8em 1.6em' } }}
          onClose={() => {
            setIsOpenJobSummary(false);
            setMenuAnchorElement(undefined);
          }}
          open={isOpenJobSummary}
          variant="menu"
        >
          {jobList}
        </Menu>
      ),
      [isOpenJobSummary, jobList, menuAnchorElement],
    );

    return jobSummary;
  },
);

JobSummary.defaultProps = JOB_SUMMARY_DEFAULT_PROPS;
JobSummary.displayName = 'JobSummary';

export type { JobSummaryForwardedRefContent, JobSummaryProps };

export default JobSummary;