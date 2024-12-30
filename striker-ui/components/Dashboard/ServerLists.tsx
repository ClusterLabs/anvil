import { Grid } from '@mui/material';
import { useMemo } from 'react';

import { toAnvilOverviewList } from '../../lib/api_converters';
import List from '../List';
import ServerSummary from './ServerSummary';
import Spinner from '../Spinner';
import useFetch from '../../hooks/useFetch';

const ServerLists: React.FC<ServerListProps> = (props) => {
  const { groups, servers } = props;

  const { altData: anvils, loading: loadingAnvils } = useFetch(`/anvil`, {
    mod: toAnvilOverviewList,
  });

  const lists = useMemo<React.ReactNode[]>(() => {
    if (!anvils) {
      return [];
    }

    const groupEntries = Object.entries(groups);

    return groupEntries.reduce<React.ReactNode[]>(
      (elements, [groupName, group]) => {
        if (!group.length) return elements;

        const groupUuids = group.reduce<Record<string, string>>(
          (previous, uuid) => {
            previous[uuid] = uuid;

            return previous;
          },
          {},
        );

        elements.push(
          <Grid key={`${groupName}`} item width="100%">
            <List
              header
              listItems={groupUuids}
              renderListItem={(uuid) => (
                <ServerSummary anvils={anvils} servers={servers} uuid={uuid} />
              )}
            />
          </Grid>,
        );

        return elements;
      },
      [],
    );
  }, [anvils, groups, servers]);

  if (loadingAnvils) {
    return (
      <Grid container spacing="1em">
        <Spinner mt={0} />
      </Grid>
    );
  }

  return (
    <Grid container spacing="1em">
      {...lists}
    </Grid>
  );
};

export default ServerLists;
