import Grid from '@mui/material/Grid';
import { useMemo } from 'react';

import Divider from '../Divider';
import ServerPreview from './ServerPreview';

const ServerPanels: React.FC<ServerPanelsProps> = (props) => {
  const { groups, servers } = props;

  const panels = useMemo<React.ReactNode[]>(() => {
    const groupEntries = Object.entries(groups);

    return groupEntries.reduce<React.ReactNode[]>(
      (elements, [groupName, group], groupIndex, array) => {
        if (!group.length) {
          return elements;
        }

        group.forEach((uuid) => {
          const server = servers[uuid];

          elements.push(
            <Grid key={`${uuid}-panel`} item xs={1}>
              <ServerPreview server={server} />
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
  }, [groups, servers]);

  return (
    <Grid
      columns={{
        xs: 1,
        sm: 2,
        md: 3,
        lg: 4,
        xl: 6,
      }}
      container
      spacing="1em"
    >
      {panels}
    </Grid>
  );
};

export default ServerPanels;
