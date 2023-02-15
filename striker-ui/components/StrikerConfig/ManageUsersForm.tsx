import { FC, useEffect } from 'react';

import api from '../../lib/api';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import { BodyText } from '../Text';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

const ManageUsersForm: FC = () => {
  const { protect } = useProtect();

  const [listMessage, setListMessage] = useProtectedState<Message>(
    { children: `No users found.` },
    protect,
  );
  const [users, setUsers] = useProtectedState<
    UserOverviewMetadataList | undefined
  >(undefined, protect);

  useEffect(() => {
    if (!users) {
      api
        .get<UserOverviewMetadataList>('/user')
        .then(({ data }) => {
          setUsers(data);
        })
        .catch((error) => {
          // Initialize to prevent infinite fetch.
          setUsers({});
          setListMessage(handleAPIError(error));
        });
    }
  }, [setListMessage, setUsers, users]);

  return (
    <ExpandablePanel header="Manage users" loading={!users}>
      <List
        allowEdit={false}
        listEmpty={<MessageBox {...listMessage} />}
        listItems={users}
        renderListItem={(userUUID, { userName }) => (
          <BodyText>{userName}</BodyText>
        )}
      />
    </ExpandablePanel>
  );
};

export default ManageUsersForm;
