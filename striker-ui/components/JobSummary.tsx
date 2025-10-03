import MuiMenu from '@mui/material/Menu';
import React, {
  forwardRef,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';
import { toast } from 'react-toastify';

import { DialogWithHeader } from './Dialog';
import FlexBox from './FlexBox';
import JobDetail from './JobDetail';
import JobSummaryItem from './JobSummaryItem';
import List from './List';
import { last, now } from '../lib/time';
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

const JobSummary = forwardRef<JobSummaryForwardedRefContent, JobSummaryProps>(
  (
    {
      getJobUrl = () => '/job',
      onFetchSuccessAppend,
      openInitially = false,
      refreshInterval = 5000,
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

    // Epoch in seconds, set at pre-render
    const loaded = useMemo(() => now(), []);

    const { data: jobs } = useFetch<APIJobOverviewList>(getJobUrl(loaded), {
      onError: () => {
        // TODO: show no jobs until toasts are in place.
      },
      onSuccess: (rawJobs) => {
        const responded = now();

        Object.keys(rawJobs).forEach((uuid) => {
          const { [uuid]: rawJob } = rawJobs;

          const toastId = `job-toast-${uuid}`;

          if (rawJob.progress < 100) {
            // Handle incomplete jobs...

            if (toast.isActive(toastId)) {
              // Update the toast contents when it already exists.
              toast.update<React.ReactNode>(toastId, {
                render: <JobSummaryItem job={rawJob} />,
              });

              return;
            }

            // Make a new toast when it's new.
            toast<React.ReactNode>(<JobSummaryItem job={rawJob} />, {
              autoClose: false,
              onClick: () => {
                setJobUuid(uuid);

                detailDialogRef.current?.setOpen(true);
              },
              toastId,
            });

            return;
          }

          // Handle completed jobs...

          if (
            last(rawJob.modified, refreshInterval / 1000, {
              now: responded,
            })
          ) {
            toast.dismiss(toastId);

            const label = rawJob.title || rawJob.name;

            if (rawJob.error.count) {
              toast.error<React.ReactNode>(
                <>Finished &quot;{label}&quot; with errors</>,
              );
            } else {
              toast.success<React.ReactNode>(<>Finished &quot;{label}&quot;</>);
            }
          }
        });

        onFetchSuccessAppend?.call(null, rawJobs);
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
            renderListItem={(uuid, job) => <JobSummaryItem job={job} />}
            scroll
          />
        </FlexBox>
      ),
      [jobs],
    );

    return (
      <>
        <MuiMenu
          anchorEl={menuAnchorElement}
          onClose={() => {
            setIsOpenJobSummary(false);
            setMenuAnchorElement(undefined);
          }}
          open={isOpenJobSummary}
          variant="menu"
        >
          {jobList}
        </MuiMenu>
        <DialogWithHeader header="" ref={detailDialogRef} showClose wide>
          {jobUuid && <JobDetail uuid={jobUuid} />}
        </DialogWithHeader>
      </>
    );
  },
);

JobSummary.displayName = 'JobSummary';

export type { JobSummaryForwardedRefContent, JobSummaryProps };

export default JobSummary;
