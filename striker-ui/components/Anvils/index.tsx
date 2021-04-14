import Panel from '../Panel';
import PeriodicFetch from '../../lib/fetchers/periodicFetch';
import SelectedAnvil from './SelectedAnvil';
import AnvilList from './AnvilList';

const Anvils = ({ list }: { list: AnvilList | undefined }): JSX.Element => {
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
      <SelectedAnvil anvil={anvils[0]} />
      <AnvilList list={anvils} />
    </Panel>
  );
};

export default Anvils;
