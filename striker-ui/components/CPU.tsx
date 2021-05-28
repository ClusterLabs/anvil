import { useContext } from 'react';
import { Box } from '@material-ui/core';
import { Panel } from './Panels';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { AnvilContext } from './AnvilContext';
import Spinner from './Spinner';

const CPU = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data, isLoading } = PeriodicFetch<AnvilCPU>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_cpu?anvil_uuid=${uuid}`,
  );

  const cpuData =
    isLoading || !data ? { allocated: 0, cores: 0, threads: 0 } : data;

  return (
    <Panel>
      <HeaderText text="CPU" />
      {!isLoading ? (
        <>
          <Box display="flex" width="100%">
            <Box flexGrow={1} style={{ marginLeft: '1em', marginTop: '1em' }}>
              <BodyText text={`Total Cores: ${cpuData.cores}`} />
              <BodyText text={`Total Threads: ${cpuData.threads}`} />
              <BodyText text={`Allocated Cores: ${cpuData.allocated}`} />
            </Box>
          </Box>
        </>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default CPU;
