import { Grid } from '@mui/material';
import { useMemo } from 'react';

import MessageBox from './MessageBox';
import PieProgress from './PieProgress';
import Spinner from './Spinner';
import sxstring from '../lib/sxstring';
import { BodyText } from './Text';
import useFetch from '../hooks/useFetch';

const JobProgressList: React.FC<JobProgressListProps> = (props) => {
  const { commands, getLabel, names, progress, uuids } = props;

  const qs = useMemo<string>(() => {
    const params = new URLSearchParams();

    if (names) {
      names.forEach((name) => {
        params.append('name', name);
      });
    }

    if (commands) {
      commands.forEach((command) => {
        params.append('command', command);
      });
    }

    return params.toString();
  }, [commands, names]);

  const { altData: jobs, loading } = useFetch<
    APIJobOverviewList,
    APIJobOverview[]
  >(`/job?${qs}`, {
    mod: (data) => {
      let scope: APIJobOverview[];

      if (uuids) {
        scope = uuids.reduce<APIJobOverview[]>((previous, uuid) => {
          const { [uuid]: job } = data;

          if (job) {
            previous.push(job);
          }

          return previous;
        }, []);
      } else {
        scope = Object.values(data);
      }

      const total = scope.reduce<number>(
        (previous, job) => previous + job.progress,
        0,
      );

      progress.set(total / scope.length);

      return scope;
    },
    refreshInterval: 3000,
  });

  const label = useMemo(
    () => sxstring(getLabel?.call(null, progress.value), BodyText),
    [getLabel, progress.value],
  );

  if (loading) {
    return <Spinner mt={0} />;
  }

  if (!jobs) {
    return <MessageBox type="warning">Failed to get jobs.</MessageBox>;
  }

  if (!jobs.length) {
    return null;
  }

  return (
    <Grid alignItems="center" columnSpacing="0.5em" container>
      {...jobs.map<React.ReactNode>((job) => (
        <Grid item key={`${job.uuid}-progress`}>
          <PieProgress
            error={Boolean(job.error.count)}
            slotProps={{
              pie: {
                size: '1em',
              },
            }}
            value={job.progress}
          />
        </Grid>
      ))}
      <Grid item xs>
        {label}
      </Grid>
    </Grid>
  );
};

export default JobProgressList;
