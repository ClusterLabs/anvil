import { Grid } from '@mui/material';
import * as prettyBytes from 'pretty-bytes';
import { useMemo } from 'react';

import { AllocationBar } from './Bars';
import { Panel } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';

// TODO: need to be removed or revised because it's likely unused.
const Storage = ({ uuid }: { uuid: string }): JSX.Element => {
  const { data: { free = 0, total = 0 } = {}, isLoading } =
    periodicFetch<AnvilMemory>(
      `${process.env.NEXT_PUBLIC_API_URL}/get_memory?anvil_uuid=${uuid}`,
    );

  const contentLayoutElement = useMemo(
    () => (
      <Grid container alignItems="center" justifyContent="space-around">
        <Grid item xs={12}>
          <HeaderText text="Storage Resync" />
        </Grid>
        <Grid item xs={5}>
          <BodyText
            text={`Allocated: ${prettyBytes.default(total - free, {
              binary: true,
            })}`}
          />
        </Grid>
        <Grid item xs={4}>
          <BodyText
            text={`Free: ${prettyBytes.default(free, {
              binary: true,
            })}`}
          />
        </Grid>
        <Grid item xs={10}>
          <AllocationBar allocated={((total - free) / total) * 100} />
        </Grid>
      </Grid>
    ),
    [free, total],
  );
  const contentAreaElement = useMemo(
    () => (isLoading ? <Spinner /> : contentLayoutElement),
    [contentLayoutElement, isLoading],
  );

  return <Panel>{contentAreaElement}</Panel>;
};

export default Storage;
