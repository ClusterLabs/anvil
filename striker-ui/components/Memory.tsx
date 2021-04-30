import { useContext } from 'react';
import { Box } from '@material-ui/core';
import * as prettyBytes from 'pretty-bytes';
import { Panel } from './Panels';
import { AllocationBar } from './Bars';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { AnvilContext } from './AnvilContext';

const Memory = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const { data, isLoading } = PeriodicFetch<AnvilMemory>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_memory?anvil_uuid=${uuid}`,
  );

  const memoryData = isLoading || !data ? { total: 0, free: 0 } : data;

  return (
    <Panel>
      <HeaderText text="Memory" />
      <Box display="flex" width="100%">
        <Box flexGrow={1}>
          <BodyText
            text={`Allocated: ${prettyBytes.default(
              memoryData.total - memoryData.free,
              {
                binary: true,
              },
            )}`}
          />
        </Box>
        <Box>
          <BodyText
            text={`Free: ${prettyBytes.default(memoryData.free, {
              binary: true,
            })}`}
          />
        </Box>
      </Box>
      <Box display="flex" width="100%">
        <Box flexGrow={1}>
          <AllocationBar
            allocated={
              ((memoryData.total - memoryData.free) / memoryData.total) * 100
            }
          />
        </Box>
      </Box>
      <Box display="flex" justifyContent="center" width="100%">
        <BodyText
          text={`Total Memory: ${prettyBytes.default(memoryData.total, {
            binary: true,
          })}`}
        />
      </Box>
    </Panel>
  );
};

export default Memory;
