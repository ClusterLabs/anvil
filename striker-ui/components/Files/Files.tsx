import { Panel } from '../Panels';
import Spinner from '../Spinner';
import { HeaderText } from '../Text';

const Files = (): JSX.Element => {
  return (
    <Panel>
      <HeaderText text="Files" />
      <Spinner />
    </Panel>
  );
};

export default Files;
