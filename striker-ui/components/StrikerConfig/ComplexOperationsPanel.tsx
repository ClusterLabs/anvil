import { FC } from 'react';

import ConfigPeersForm from './ConfigPeersForm';
import ManageChangedSSHKeysForm from './ManageChangedSSHKeysForm';
import ManageUsersForm from './ManageUsersForm';
import { Panel } from '../Panels';

const ComplexOperationsPanel: FC = () => (
  <Panel>
    <ConfigPeersForm />
    <ManageChangedSSHKeysForm />
    <ManageUsersForm />
  </Panel>
);

export default ComplexOperationsPanel;
