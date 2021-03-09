import Panel from './Panel';
import Text from './Text/HeaderText';
import InnerPanel from './InnerPanel';

const ReplicatedStorage = (): JSX.Element => {
  return (
    <Panel>
      <Text text="Replicated Storage" />
      <InnerPanel />
    </Panel>
  );
};

export default ReplicatedStorage;
