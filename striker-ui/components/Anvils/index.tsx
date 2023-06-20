import { Panel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import SelectedAnvil from './SelectedAnvil';
import AnvilList from './AnvilList';

import sortAnvils from './sortAnvils';
import API_BASE_URL from '../../lib/consts/API_BASE_URL';

const Anvils = ({ list }: { list: AnvilList | undefined }): JSX.Element => {
  const anvils: AnvilListItem[] = [];

  list?.anvils.forEach((anvil: AnvilListItem) => {
    const { anvil_uuid } = anvil;

    const { data } = periodicFetch<AnvilStatus>(
      `${API_BASE_URL}/anvil/${anvil_uuid}`,
    );
    anvils.push({
      ...anvil,
      ...data,
    });
  });
  return (
    <Panel>
      <SelectedAnvil list={anvils} />
      <AnvilList list={sortAnvils(anvils)} />
    </Panel>
  );
};

export default Anvils;
