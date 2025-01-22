import { createElement, useState } from 'react';

import AnvilList from './AnvilList';
import { Panel } from '../Panels';
import SelectedAnvil from './SelectedAnvil';
import sortAnvils from './sortAnvils';
import useFetch from '../../hooks/useFetch';

const Anvil: React.FC<{
  anvils: {
    get: () => AnvilListItem[];
    set: React.Dispatch<React.SetStateAction<AnvilListItem[]>>;
  };
  uuid: string;
}> = (props) => {
  const { anvils, uuid } = props;

  useFetch<AnvilStatus>(`/anvil/${uuid}`, {
    onSuccess: (data) => {
      const i = anvils.get().findIndex((anvil) => anvil.anvil_uuid === uuid);

      if (i === -1) {
        return;
      }

      anvils.set((previous) => {
        const clone = [...previous];

        clone[i] = {
          ...clone[i],
          ...data,
        };

        return clone;
      });
    },
    periodic: true,
  });

  return <></>;
};

const Anvils: React.FC<{ list?: AnvilList }> = (props) => {
  const { list } = props;

  const [anvils, setAnvils] = useState<AnvilListItem[]>([]);

  list?.anvils.forEach((anvil) => {
    const { anvil_uuid: uuid } = anvil;

    createElement(Anvil, {
      anvils: {
        get: () => anvils,
        set: setAnvils,
      },
      uuid,
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
