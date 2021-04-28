import { useContext } from 'react';
import Panel from '../Panel';
import Text from '../Text/HeaderText';
import AnvilNode from './AnvilNode';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import { AnvilContext } from '../AnvilContext';

const Nodes = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data } = PeriodicFetch<AnvilStatus>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=`,
    uuid,
  );

  return (
    <Panel>
      <Text text="Nodes" />
      {anvil.findIndex((a) => a.anvil_uuid === uuid) !== -1 && (
        <AnvilNode
          nodes={anvil[anvil.findIndex((a) => a.anvil_uuid === uuid)].nodes.map(
            (node, index) => {
              return { ...node, ...data?.nodes[index] };
            },
          )}
        />
      )}
    </Panel>
  );
};

export default Nodes;
