import Panel from './Panel';
import { HeaderText } from './Text';
import ProgressBar from './ProgressBarBck';

const ReplicatedStorage = (): JSX.Element => {
  return (
    <Panel>
      <HeaderText text="Replicated Storage" />
      <ProgressBar allocated={20} />
    </Panel>
  );
};

export default ReplicatedStorage;
