import Grid from '@mui/material/Grid';
import { useMemo } from 'react';

import { toAnvilOverviewList } from '../../lib/api_converters';
import Divider from '../Divider';
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
      (elements, [groupName, group], groupIndex, array) => {
        if (!group.length) {
          return elements;
        }

        group.forEach((uuid) => {
          elements.push(
            <Grid key={`${uuid}-summary`} item xs={1}>
              <ServerSummary anvils={anvils} servers={servers} uuid={uuid} />
            </Grid>,
          );
        });

        const last = groupIndex + 1 === array.length;

        if (!last) {
          elements.push(
            <Grid key={`${groupName}-end`} item width="100%">
              <Divider orientation="horizontal" />
            </Grid>,
          );
        }

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
    <Grid
      columns={{
        xs: 1,
        md: 2,
        lg: 3,
        xl: 4,
      }}
      container
      spacing="1em"
    >
      {...lists}
    </Grid>
  );
};

export default ServerLists;
