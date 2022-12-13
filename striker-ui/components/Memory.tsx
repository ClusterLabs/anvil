import { Box } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';
import { useContext } from 'react';

import { AnvilContext } from './AnvilContext';
import { AllocationBar } from './Bars';
import { Panel, PanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';

const Memory = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data: { allocated = 0, reserved = 0, total = 0 } = {}, isLoading } =
    periodicFetch<AnvilMemory>(
      `${process.env.NEXT_PUBLIC_API_URL}/get_memory?anvil_uuid=${uuid}`,
    );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="Memory" />
      </PanelHeader>
      {!isLoading ? (
        <>
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <BodyText
                text={`Allocated: ${prettyBytes.default(allocated, {
                  binary: true,
                })}`}
              />
            </Box>
            <Box>
              <BodyText
                text={`Free: ${prettyBytes.default(total - allocated, {
                  binary: true,
                })}`}
              />
            </Box>
          </Box>
          <Box display="flex" width="100%">
            <Box flexGrow={1}>
              <AllocationBar allocated={(allocated / total) * 100} />
            </Box>
          </Box>
          <Box display="flex" justifyContent="center" width="100%">
            <BodyText
              text={`Total: ${prettyBytes.default(total, {
                binary: true,
              })} | Reserved: ${prettyBytes.default(reserved, {
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
