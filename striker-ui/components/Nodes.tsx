import InnerPanel from './InnerPanel';
import Panel from './Panel';
import Text from './Text/HeaderText';

const Nodes = (): JSX.Element => {
  return (
    <Panel>
      <Text text="Nodes" />
      <InnerPanel />
    </Panel>
  );
};

export default Nodes;
