import ManageFenceList from './ManageFenceList';
import { Panel, PanelHeader } from '../Panels';
import { HeaderText } from '../Text';

const ManageFencePanel: React.FC = () => (
  <Panel>
    <PanelHeader>
      <HeaderText>Manage fence devices</HeaderText>
    </PanelHeader>
    <ManageFenceList />
  </Panel>
);

export default ManageFencePanel;
