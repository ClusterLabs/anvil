import { Panel } from './Panels';
import { HeaderText } from './Text';

const Resource = ({
  resource,
}: {
  resource: AnvilReplicatedStorage;
}): JSX.Element => {
  return (
    <Panel>
      <HeaderText text={`Resource: ${resource.resource_name}`} />
    </Panel>
  );
};

export default Resource;
