import { useContext } from 'react';
import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import { AnvilContext } from '../AnvilContext';
import AnvilHost from './AnvilHost';
import hostsSanitizer from '../../lib/sanitizers/hostsSanitizer';
import { Panel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import { HeaderText } from '../Text';
import Spinner from '../Spinner';

const Hosts = ({ anvil }: { anvil: AnvilListItem[] }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);

  const { data, isLoading } = periodicFetch<AnvilStatus>(
    `${API_BASE_URL}/anvil/${uuid}`,
  );

  const anvilIndex = anvil.findIndex((a) => a.anvil_uuid === uuid);

  return (
    <Panel>
      <HeaderText text="Subnodes" />
      {!isLoading ? (
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
