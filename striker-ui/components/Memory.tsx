import { useContext } from 'react';
import { Box } from '@material-ui/core';
import * as prettyBytes from 'pretty-bytes';
import { Panel } from './Panels';
import { AllocationBar } from './Bars';
import { HeaderText, BodyText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';
import { AnvilContext } from './AnvilContext';
import Spinner from './Spinner';

const Memory = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const { data, isLoading } = PeriodicFetch<AnvilMemory>(
    `${process.env.NEXT_PUBLIC_API_URL}/get_memory?anvil_uuid=${uuid}`,
  );

  const memoryData =
    isLoading || !data ? { total: 0, allocated: 0, reserved: 0 } : data;

  return (
    <Panel>
      <HeaderText text="Memory" />
      {!isLoading ? (
        <>
          {' '}
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <BodyText
                text={`Allocated: ${prettyBytes.default(memoryData.allocated, {
                  binary: true,
                })}`}
              />
            </Box>
            <Box>
              <BodyText
                text={`Free: ${prettyBytes.default(
                  memoryData.total - memoryData.allocated,
                  {
                    binary: true,
                  },
                )}`}
              />
            </Box>
          </Box>
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <AllocationBar
                allocated={(memoryData.allocated / memoryData.total) * 100}
              />
            </Box>
          </Box>
          <Box display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total: ${prettyBytes.default(memoryData.total, {
                binary: true,
              })} | Reserved: ${prettyBytes.default(memoryData.reserved, {
                binary: true,
              })}`}
            />
          </Box>
        </>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default Memory;
