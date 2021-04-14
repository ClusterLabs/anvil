import Panel from './Panel';
import SharedStorageNode from './SharedStorageNode';
import { HeaderText } from './Text';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const SharedStorage = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const { data } = PeriodicFetch<AnvilSharedStorage>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_shared_storage?anvil_uuid=`,
    anvil?.anvil_uuid,
  );

  return (
    <Panel>
      <HeaderText text="Shared Storage" />
      {data &&
        data.file_systems[0]?.nodes.map(
          (node: AnvilSharedStorageNode, index: number): JSX.Element => (
            <SharedStorageNode
              node={{ ...node, nodeInfo: anvil.nodes[index] }}
              key={anvil.nodes[index].node_uuid}
            />
          ),
        )}
    </Panel>
  );
};

export default SharedStorage;
