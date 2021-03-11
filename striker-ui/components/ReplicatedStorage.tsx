import Panel from './Panel';
import { HeaderText } from './Text';
import InnerPanel from './InnerPanel';
import ProgressBar from './ProgressBar';

const ReplicatedStorage = (): JSX.Element => {
  return (
    <Panel>
      <HeaderText text="Replicated Storage" />
      <InnerPanel />
      <ProgressBar allocated={20} />
    </Panel>
  );
};

export default ReplicatedStorage;
