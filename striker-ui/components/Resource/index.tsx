import { Panel } from '../Panels';
import { HeaderText } from '../Text';
import ResourceVolumes from './ResourceVolumes';



const Resource = ({
  resource,
}: {
  resource: AnvilReplicatedStorage;
}): React.ReactElement => (
  <Panel>
    <HeaderText text={`Resource: ${resource.resource_name}`} />
    <ResourceVolumes resource={resource} />
  </Panel>
);

export default Resource;
