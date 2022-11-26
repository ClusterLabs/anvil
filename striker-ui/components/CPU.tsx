import { useContext, useMemo } from 'react';

import { AnvilContext } from './AnvilContext';
import FlexBox from './FlexBox';
import { Panel, PanelHeader } from './Panels';
import periodicFetch from '../lib/fetchers/periodicFetch';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';

const CPU = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data: { allocated = 0, cores = 0, threads = 0 } = {}, isLoading } =
    periodicFetch<AnvilCPU>(
      `${process.env.NEXT_PUBLIC_API_URL}/get_cpu?anvil_uuid=${uuid}`,
    );

  const contentAreaElement = useMemo(
    () =>
      isLoading ? (
        <Spinner />
      ) : (
        <FlexBox spacing={0}>
          <BodyText text={`Total Cores: ${cores}`} />
          <BodyText text={`Total Threads: ${threads}`} />
          <BodyText text={`Allocated Cores: ${allocated}`} />
        </FlexBox>
      ),
    [allocated, cores, isLoading, threads],
  );

  return (
    <Panel>
      <PanelHeader>
        <HeaderText text="CPU" />
      </PanelHeader>
      {contentAreaElement}
    </Panel>
  );
};

export default CPU;
