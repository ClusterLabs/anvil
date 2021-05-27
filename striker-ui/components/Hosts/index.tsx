import { useContext } from 'react';
import { Panel } from '../Panels';
import { HeaderText } from '../Text';
import AnvilHost from './AnvilHost';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import { AnvilContext } from '../AnvilContext';

const Hosts = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data } = PeriodicFetch<AnvilStatus>(
    `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=${uuid}`,
  );

  return (
    <Panel>
      <HeaderText text="Hosts" />
      {anvil.findIndex((a) => a.anvil_uuid === uuid) !== -1 && data && (
        <AnvilHost
          hosts={anvil[anvil.findIndex((a) => a.anvil_uuid === uuid)].hosts.map(
            (host, index) => {
              return data.hosts[index];
            },
          )}
        />
      )}
    </Panel>
  );
};

export default Hosts;
