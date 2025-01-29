import { useContext, useMemo } from 'react';

import { AnvilContext } from './AnvilContext';
import FlexBox from './FlexBox';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { HeaderText, BodyText } from './Text';
import useFetch from '../hooks/useFetch';

const CPU = (): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data: { allocated = 0, cores = 0, threads = 0 } = {}, loading } =
    useFetch<AnvilCPU>(`/anvil/${uuid}/cpu`, {
      periodic: true,
    });

  const contentAreaElement = useMemo(
    () =>
      loading ? (
        <Spinner />
      ) : (
        <FlexBox spacing={0}>
          <BodyText text={`Total Cores: ${cores}`} />
          <BodyText text={`Total Threads: ${threads}`} />
          <BodyText text={`Allocated Cores: ${allocated}`} />
        </FlexBox>
      ),
    [allocated, cores, loading, threads],
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
