import Panel from './Panel';
import Text from './Text/HeaderText';
import AnvilNode from './AnvilNode';
import PeriodicFetch from '../lib/fetchers/periodicFetch';

const Nodes = ({ anvil }: { anvil: AnvilListItem }): JSX.Element => {
  const { data } = PeriodicFetch<AnvilStatus>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=`,
    anvil?.anvil_uuid,
  );
  /* eslint-disable no-param-reassign */
  if (anvil) anvil.anvil_status = data;

  return (
    <Panel>
      <Text text="Nodes" />
      <AnvilNode node={anvil?.anvil_status} />
    </Panel>
  );
};

export default Nodes;
