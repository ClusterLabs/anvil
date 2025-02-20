import { Grid } from '@mui/material';
import { useMemo } from 'react';

import MessageBox from '../MessageBox';
import PieProgress from '../PieProgress';
import Spinner from '../Spinner';
import { BodyText } from '../Text';
import useFetch from '../../hooks/useFetch';

const DeleteSshKeyConflictProgress: React.FC<
  DeleteSshKeyConflictProgressProps
> = (props) => {
  const { jobs: ids, progress: jobProgress } = props;

  // Only look at progress of the job targeting the local striker
  const scope = useMemo(
    () => Object.keys(ids).filter((key) => ids[key].local),
    [ids],
  );

  const { altData: jobs, loading } = useFetch<
    APIJobOverviewList,
    APIJobOverview[]
  >('/job?broken_keys', {
    mod: (data) => {
      let total = 0;

      const result = scope.reduce<APIJobOverview[]>((previous, uuid) => {
        const { [uuid]: job } = data;

        if (job) {
          previous.push(job);

          total += job.progress;
        }

        return previous;
      }, []);

      jobProgress.setTotal(total / result.length);

      return result;
    },
    refreshInterval: 2000,
  });

  if (loading) {
    return <Spinner mt={0} />;
  }

  if (!jobs) {
    return (
      <MessageBox type="warning">Failed to get the list of jobs.</MessageBox>
    );
  }

  return (
    <Grid alignItems="center" container spacing="0.5em">
      <Grid item width="100%">
        <BodyText>
          {jobProgress.total === 100 ? 'Finished deletion.' : 'Deleting...'}
        </BodyText>
      </Grid>
      {...jobs.map<React.ReactNode>((job) => {
        const { progress, uuid } = job;

        return (
          <Grid item key={`${uuid}-progress`}>
            <PieProgress
              slotProps={{
                pie: {
                  size: '1em',
                },
              }}
              value={progress}
            />
          </Grid>
        );
      })}
    </Grid>
  );
};

export default DeleteSshKeyConflictProgress;
