import { useMemo } from 'react';

import List from '../List';
import { BodyText } from '../Text';

const ProvisionServerExistingList: React.FC<
  ProvisionServerExistingListProps
> = (props) => {
  const { resources } = props;

  const reversed = useMemo(() => {
    const servers = Object.values(resources.servers);

    return servers
      .sort((a, b) =>
        b.name.localeCompare(a.name, undefined, {
          numeric: true,
        }),
      )
      .reduce<Record<string, ProvisionServerResourceServer>>(
        (previous, server) => {
          previous[server.uuid] = server;

          return previous;
        },
        {},
      );
  }, [resources.servers]);

  return (
    <List
      header="Existing"
      listItems={reversed}
      listProps={{
        dense: true,
        sx: {
          maxHeight: 'calc(60vh - 12em)',
        },
      }}
      renderListItem={(uuid, server) => <BodyText>{server.name}</BodyText>}
      scroll
    />
  );
};

export default ProvisionServerExistingList;
