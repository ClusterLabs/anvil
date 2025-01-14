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
  const { jobs: ids } = props;

  const uuids = useMemo(() => Object.keys(ids), [ids]);

  const { altData: jobs, loading } = useFetch<
    APIJobOverviewList,
    APIJobOverview[]
  >('/job?broken_keys', {
    mod: (data) =>
      uuids.reduce<APIJobOverview[]>((previous, uuid) => {
        const { [uuid]: job } = data;

        if (job) {
          previous.push(job);
        }

        return previous;
      }, []),
    refreshInterval: 2000,
  });

  const totalProgress = useMemo(() => {
    let total = 0;
    if (!jobs) {
      return total;
    }

    jobs.forEach((job) => {
      total += job.progress;
    });

    return total / jobs.length;
  }, [jobs]);

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
          {totalProgress === 100 ? 'Finished deletion.' : 'Deleting...'}
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
