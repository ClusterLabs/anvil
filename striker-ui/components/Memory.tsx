import { Box } from '@mui/material';
import { useContext, useMemo } from 'react';

import API_BASE_URL from '../lib/consts/API_BASE_URL';

import { AnvilContext } from './AnvilContext';
import { AllocationBar } from './Bars';
import { toBinaryByte } from '../lib/format_data_size_wrappers';
import { Panel, PanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';

const Memory = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const {
    data: { allocated = '0', reserved = '0', total = '0' } = {},
    isLoading,
  } = periodicFetch<AnvilMemory>(`${API_BASE_URL}/anvil/${uuid}/memory`);

  const nAllocated = useMemo(() => BigInt(allocated), [allocated]);
  const nReserved = useMemo(() => BigInt(reserved), [reserved]);
  const nTotal = useMemo(() => BigInt(total), [total]);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Memory" />
      </PanelHeader>
      {!isLoading ? (
        <>
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <BodyText text={`Allocated: ${toBinaryByte(nAllocated)}`} />
            </Box>
            <Box>
              <BodyText
                text={`Free: ${toBinaryByte(
                  nTotal - (nReserved + nAllocated),
                )}`}
              />
            </Box>
          </Box>
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <AllocationBar
                allocated={Number(
                  ((nReserved + nAllocated) * BigInt(100)) / nTotal,
                )}
              />
            </Box>
          </Box>
          <Box display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total: ${toBinaryByte(nTotal)} | Reserved: ${toBinaryByte(
                nReserved,
              )}`}
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
