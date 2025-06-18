import MuiBox from '@mui/material/Box';
import { useContext, useMemo } from 'react';

import { AnvilContext } from './AnvilContext';
import { AllocationBar } from './Bars';
import { toBinaryByte } from '../lib/format_data_size_wrappers';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';
import useFetch from '../hooks/useFetch';

const Memory = (): React.ReactElement => {
  const { uuid } = useContext(AnvilContext);

  const {
    data: { allocated = '0', reserved = '0', total = '0' } = {},
    loading,
  } = useFetch<AnvilMemory>(`/anvil/${uuid}/memory`, {
    periodic: true,
  });

  const nAllocated = useMemo(() => BigInt(allocated), [allocated]);
  const nReserved = useMemo(() => BigInt(reserved), [reserved]);
  const nTotal = useMemo(() => BigInt(total), [total]);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Memory" />
      </PanelHeader>
      {!loading ? (
        <>
          <MuiBox display="flex" width="100%">
            <MuiBox flexGrow={1}>
              <BodyText text={`Allocated: ${toBinaryByte(nAllocated)}`} />
            </MuiBox>
            <MuiBox>
              <BodyText
                text={`Free: ${toBinaryByte(
                  nTotal - (nReserved + nAllocated),
                )}`}
              />
            </MuiBox>
          </MuiBox>
          <MuiBox display="flex" width="100%">
            <MuiBox flexGrow={1}>
              <AllocationBar
                allocated={
                  nTotal
                    ? Number(((nReserved + nAllocated) * BigInt(100)) / nTotal)
                    : 0
                }
              />
            </MuiBox>
          </MuiBox>
          <MuiBox display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total: ${toBinaryByte(nTotal)} | Reserved: ${toBinaryByte(
                nReserved,
              )}`}
            />
          </MuiBox>
        </>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default Memory;
