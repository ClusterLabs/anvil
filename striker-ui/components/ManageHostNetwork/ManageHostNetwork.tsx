import { useMemo, useState } from 'react';

import Divider from '../Divider';
import HostTabs from './HostTabs';
import { Panel } from '../Panels';
import PrepareHostNetwork from './PrepareHostNetwork';
import useFetch from '../../hooks/useFetch';
import TabContent from '../TabContent';
import Spinner from '../Spinner';

const ManageHostNetwork: React.FC = () => {
  const [hostUuid, setHostUuid] = useState<false | string>(false);

  const { data: hosts } = useFetch<APIHostOverviewList>(
    '/host?type=dr&type=subnode',
  );

  const hostValues = useMemo<APIHostOverview[] | undefined>(
    () => hosts && Object.values(hosts),
    [hosts],
  );

  if (!hostValues) {
    return (
      <Panel>
        <Spinner />
      </Panel>
    );
  }

  return (
    <Panel>
      <HostTabs list={hostValues} setValue={setHostUuid} value={hostUuid} />
      {hostUuid && <Divider sx={{ margin: '2em 0' }} />}
      {hostValues.map((host) => (
        <TabContent
          changingTabId={hostUuid}
          key={`cell-${host.hostUUID}`}
          tabId={host.hostUUID}
        >
          <PrepareHostNetwork uuid={host.hostUUID} />
        </TabContent>
      ))}
    </Panel>
  );
};

export default ManageHostNetwork;
