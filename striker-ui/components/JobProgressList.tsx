import Grid from '@mui/material/Grid';
import { useMemo, useState } from 'react';

import MessageBox from './MessageBox';
import PieProgress from './PieProgress';
import Spinner from './Spinner';
import { BodyText } from './Text';
import useFetch from '../hooks/useFetch';
import sxstring from '../lib/sxstring';
import { now } from '../lib/time';

const JobProgressList: React.FC<JobProgressListProps> = (props) => {
  const { commands, getLabel, names, progress, uuids } = props;

  const [maxJobs, setMaxJobs] = useState<number>(0);

  const loaded = useMemo<number>(() => now(), []);

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

    params.append('start', String(loaded));

    return params.toString();
  }, [commands, loaded, names]);

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

      if (maxJobs < scope.length) {
        setMaxJobs(scope.length);
      }

      return scope;
    },
    refreshInterval: 3000,
  });

  const label = useMemo(
    () => sxstring(getLabel?.(progress.value), BodyText),
    [getLabel, progress.value],
  );

  if (loading) {
    return <Spinner mt={0} />;
  }

  if (!jobs) {
    return <MessageBox type="warning">Failed to get jobs.</MessageBox>;
  }

  if (maxJobs === 0) {
    return <BodyText>Waiting for jobs to start...</BodyText>;
  }

  if (jobs.length === 0) {
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
