import { useState } from 'react';

import ManageHostList from './ManageHostList';
import { Panel, PanelHeader } from '../Panels';
import SyncIndicator from '../SyncIndicator';
import { HeaderText } from '../Text';

const ManageHostPanel: React.FC = () => {
  const [validating, setValidating] = useState<boolean>(false);

  return (
    <Panel>
      <PanelHeader>
        <HeaderText>Hosts</HeaderText>
        <SyncIndicator syncing={validating} />
      </PanelHeader>
      <ManageHostList
        onValidateHostsChange={(value) => {
          if (value !== validating) {
            setValidating(value);
          }
        }}
      />
    </Panel>
  );
};

export default ManageHostPanel;
