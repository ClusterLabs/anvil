import { Grid } from '@material-ui/core';
import Panel from './Panel';
import AllocationBar from './AllocationBar';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const CPU = ({ uuid }: { uuid: string }): JSX.Element => {
  const { data, isLoading } = PeriodicFetch<AnvilCPU>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_cpu?anvil_uuid=`,
    uuid,
  );

  const cpuData =
    isLoading || !data ? { allocated: 0, cores: 0, threads: 0 } : data;

  return (
    <Panel>
      <Grid container alignItems="center" justify="space-around">
        <Grid item xs={12}>
          <HeaderText text="CPU" />
        </Grid>
        <Grid item xs={3}>
          <BodyText text={`Allocated: ${cpuData.allocated}`} />
        </Grid>
        <Grid item xs={3}>
          <BodyText text={`Free: ${cpuData.cores - cpuData.allocated}`} />
        </Grid>
        <Grid item xs={10}>
          <AllocationBar
            allocated={(cpuData.allocated / cpuData.cores) * 100}
          />
        </Grid>
        <Grid item xs={4}>
          <BodyText
            text={`Total Cores: ${cpuData.cores}c | ${cpuData.threads}t`}
          />
        </Grid>
      </Grid>
    </Panel>
  );
};

export default CPU;
