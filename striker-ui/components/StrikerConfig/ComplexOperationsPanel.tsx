import ManageChangedSSHKeysForm from './ManageChangedSSHKeysForm';
import ManagePeerStriker from '../ManagePeerStriker/ManagePeerStriker';
import ManageUsersForm from '../ManageUser/ManageUsersForm';
import { Panel } from '../Panels';

const ComplexOperationsPanel: React.FC = () => (
  <Panel>
    <ManagePeerStriker />
    <ManageChangedSSHKeysForm />
    <ManageUsersForm />
  </Panel>
);

export default ComplexOperationsPanel;
