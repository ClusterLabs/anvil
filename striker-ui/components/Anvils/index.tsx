import { useContext } from 'react';
import Panel from '../Panel';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import SelectedAnvil from './SelectedAnvil';
import AnvilList from './AnvilList';

import { AnvilContext } from '../AnvilContext';

const Anvils = ({ list }: { list: AnvilList | undefined }): JSX.Element => {
  const { uuid } = useContext(AnvilContext);
  const anvils: AnvilListItem[] = [];

  list?.anvils.forEach((anvil: AnvilListItem) => {
    const { data } = PeriodicFetch<AnvilStatus>(
      `${process.env.NEXT_PUBLIC_API_URL}/anvils/get_status?anvil_uuid=`,
      anvil.anvil_uuid,
    );
    /* eslint-disable no-param-reassign */
    anvils.push({
      ...anvil,
      anvil_state: data?.anvil_state,
    });
  });
  return (
    <Panel>
      {uuid !== '' && (
        <SelectedAnvil
          anvil={anvils[anvils.findIndex((anvil) => anvil.anvil_uuid === uuid)]}
        />
      )}
      <AnvilList list={anvils} />
    </Panel>
  );
};

export default Anvils;
