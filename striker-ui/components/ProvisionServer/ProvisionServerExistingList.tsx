import List from '../List';
import { BodyText } from '../Text';

const ProvisionServerExistingList: React.FC<
  ProvisionServerExistingListProps
> = (props) => {
  const { resources } = props;

  return (
    <List
      header="Existing"
      listItems={resources.servers}
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
