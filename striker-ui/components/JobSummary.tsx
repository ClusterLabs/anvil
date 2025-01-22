import { Menu } from '@mui/material';
import {
  forwardRef,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';

import { DialogWithHeader } from './Dialog';
import FlexBox from './FlexBox';
import JobDetail from './JobDetail';
import List from './List';
import PieProgress from './PieProgress';
import { BodyText } from './Text';
import { elapsed, now } from '../lib/time';
import useFetch from '../hooks/useFetch';

type JobSummaryOptionalPropsWithDefault = {
  getJobUrl?: (epoch: number) => string;
  openInitially?: boolean;
};

type JobSummaryOptionalPropsWithoutDefault = {
  onFetchSuccessAppend?: (data: APIJobOverviewList) => void;
  refreshInterval?: number;
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
  getJobUrl: () => `/job`,
  onFetchSuccessAppend: undefined,
  openInitially: false,
  refreshInterval: undefined,
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
    const detailDialogRef = useRef<DialogForwardedRefContent>(null);

    const [jobUuid, setJobUuid] = useState<string | undefined>();
    const [isOpenJobSummary, setIsOpenJobSummary] =
      useState<boolean>(openInitially);
    const [menuAnchorElement, setMenuAnchorElement] = useState<
      HTMLElement | undefined
    >();

    // Epoch in seconds
    const loaded = useMemo(() => now(), []);
    const nao = now();

    const { data: jobs } = useFetch<APIJobOverviewList>(getJobUrl(loaded), {
      onError: () => {
        // TODO: show no jobs until toasts are in place.
      },
      onSuccess: (rawAnvilJobs) => {
        onFetchSuccessAppend?.call(null, rawAnvilJobs);
      },
      periodic: true,
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
            allowItemButton
            listEmpty="No running or recently completed jobs."
            listItems={jobs}
            listProps={{
              sx: { maxHeight: JOB_LIST_LENGTH, width: JOB_LIST_LENGTH },
            }}
            onItemClick={({ uuid }) => {
              setJobUuid(uuid);

              detailDialogRef.current?.setOpen(true);
            }}
            renderListItem={(uuid, job) => {
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
                <FlexBox fullWidth spacing=".2em">
                  <FlexBox row spacing=".5em">
                    <PieProgress
                      slotProps={{
                        pie: {
                          sx: {
                            flexShrink: 0,
                          },
                        },
                      }}
                      value={progress}
                    />
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
              );
            }}
            scroll
          />
        </FlexBox>
      ),
      [jobs, nao],
    );

    return (
      <>
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
        <DialogWithHeader header="" ref={detailDialogRef} showClose wide>
          {jobUuid && <JobDetail uuid={jobUuid} />}
        </DialogWithHeader>
      </>
    );
  },
);

JobSummary.defaultProps = JOB_SUMMARY_DEFAULT_PROPS;
JobSummary.displayName = 'JobSummary';

export type { JobSummaryForwardedRefContent, JobSummaryProps };

export default JobSummary;
