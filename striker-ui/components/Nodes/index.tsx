import Panel from '../Panel';
import Text from '../Text/HeaderText';
import AnvilNode from './AnvilNode';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';

const Nodes = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const { data } = PeriodicFetch<AnvilStatus>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=`,
    anvil?.anvil_uuid,
  );

  return (
    <Panel>
      <Text text="Nodes" />
      <AnvilNode
        nodes={anvil?.nodes.map((node, index) => {
          return { ...node, ...data?.nodes[index] };
        })}
      />
    </Panel>
  );
};

export default Nodes;
