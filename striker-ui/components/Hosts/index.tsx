import { useContext } from 'react';

import { AnvilContext } from '../AnvilContext';
import AnvilHost from './AnvilHost';
import hostsSanitizer from '../../lib/sanitizers/hostsSanitizer';
import { Panel } from '../Panels';
import { HeaderText } from '../Text';
import Spinner from '../Spinner';
import useFetch from '../../hooks/useFetch';

const Hosts = ({ anvil }: { anvil: AnvilListItem[] }): React.ReactElement => {
  const { uuid } = useContext(AnvilContext);

  const { data, loading } = useFetch<AnvilStatus>(`/anvil/${uuid}`, {
    periodic: true,
  });

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  return (
    <Panel>
      <HeaderText text="Subnodes" />
      {!loading ? (
        <>
          {anvilIndex !== -1 && data && (
            <AnvilHost
              hosts={hostsSanitizer(anvil[anvilIndex].hosts).reduce<
                Array<AnvilStatusHost>
              >((reducedHosts, host, index) => {
                const hostStatus = data.hosts[index];

                if (hostStatus) {
                  reducedHosts.push(hostStatus);
                }

                return reducedHosts;
              }, [])}
            />
          )}
        </>
      ) : (
        <Spinner />
      )}
    </Panel>
  );
};

export default Hosts;
