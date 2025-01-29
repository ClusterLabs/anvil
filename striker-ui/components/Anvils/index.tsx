import { Box } from '@mui/material';
import { useMemo, useState } from 'react';

import AnvilList from './AnvilList';
import { Panel } from '../Panels';
import SelectedAnvil from './SelectedAnvil';
import useFetch from '../../hooks/useFetch';

const Anvil: React.FC<{
  anvil: AnvilListItem;
  anvils: {
    set: React.Dispatch<React.SetStateAction<AnvilListItem[]>>;
    value: AnvilListItem[];
  };
}> = (props) => {
  const { anvil: overview, anvils } = props;

  useFetch<AnvilStatus>(`/anvil/${overview.anvil_uuid}`, {
    onSuccess: (data) => {
      const i = anvils.value.findIndex(
        (detail) => detail.anvil_uuid === overview.anvil_uuid,
      );

      if (i === -1) {
        anvils.set((previous) => {
          const clone = [
            ...previous,
            {
              ...overview,
              ...data,
            },
          ];

          return clone;
        });
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

  return <Box display="none" />;
};

const Anvils: React.FC<{ list: AnvilList }> = (props) => {
  const { list } = props;

  const [anvils, setAnvils] = useState<AnvilListItem[]>([]);

  const fetchers = useMemo(
    () =>
      list.anvils.map((anvil) => (
        <Anvil
          key={`${anvil.anvil_uuid}-fetcher`}
          anvil={anvil}
          anvils={{
            set: setAnvils,
            value: anvils,
          }}
        />
      )),
    [anvils, list.anvils],
  );

  return (
    <Panel>
      {fetchers}
      <SelectedAnvil list={anvils} />
      <AnvilList list={anvils} />
    </Panel>
  );
};

export default Anvils;
