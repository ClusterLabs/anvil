import { useContext } from 'react';
import { Box } from '@material-ui/core';
import { Panel } from './Panels';
import { AllocationBar } from './Bars';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { AnvilContext } from './AnvilContext';

const CPU = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data, isLoading } = PeriodicFetch<AnvilCPU>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_cpu?anvil_uuid=${uuid}`,
  );

  const cpuData =
    isLoading || !data ? { allocated: 0, cores: 0, threads: 0 } : data;

  return (
    <Panel>
      <HeaderText text="CPU" />
      <Box display="flex" width="100%">
        <Box flexGrow={1}>
          <BodyText text={`Allocated: ${cpuData.allocated}`} />
        </Box>
        <Box>
          <BodyText text={`Free: ${cpuData.cores - cpuData.allocated}`} />
        </Box>
      </Box>
      <Box display="flex" width="100%">
        <Box flexGrow={1}>
          <AllocationBar
            allocated={(cpuData.allocated / cpuData.cores) * 100}
          />
        </Box>
      </Box>
      <Box display="flex" justifyContent="center" width="100%">
        <BodyText
          text={`Total Cores: ${cpuData.cores}c | ${cpuData.threads}t`}
        />
      </Box>
    </Panel>
  );
};

export default CPU;
