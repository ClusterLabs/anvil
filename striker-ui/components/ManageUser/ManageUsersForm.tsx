import { useMemo, useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import handleFormSubmit from '../Form/handleFormSubmit';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import { BodyText } from '../Text';
import UserForm from './UserForm';
import UserInputGroup from './UserInputGroup';
import getUserFormikInitialValues from './getUserFormikInitialValues';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';
import handleAPIError from '../../lib/handleAPIError';
import buildUserSchema from './schemas/buildUserSchema';

import { INPUT_ID_USER_NAME, INPUT_ID_USER_PASSWORD } from './inputIds';

const ManageUsersForm: React.FC = () => {
  const addDialogRef = useRef<DialogForwardedRefContent>(null);
  const editDialogRef = useRef<DialogForwardedRefContent>(null);

  const confirm = useConfirmDialog();

  const [editUsers, setEditUsers] = useState<boolean>(false);

  const [listMessage, setListMessage] = useState<Message>({
    children: `No users found.`,
  });

  const [editUuid, setEditUuid] = useState<string>('');

  const {
    data: usersWithCurrent,
    loading: loadingUsers,
    mutate: getUsers,
  } = useFetch<APIUserOverviewList>(`/user`, {
    onError: (error) => {
      setListMessage(handleAPIError(error));
    },
  });

  const admin = usersWithCurrent?.current?.userName === 'admin';

  const users = useMemo(
    () =>
      usersWithCurrent &&
      Object.values(usersWithCurrent).reduce<APIUserOverviewList>(
        (previous, user) => {
          previous[user.userUUID] = user;

          return previous;
        },
        {},
      ),
    [usersWithCurrent],
  );

  const editTarget = users?.[editUuid];

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasChecks,
    resetChecks,
    setCheck,
  } = useChecklist({ list: users });

  const deleteUtils = useFormUtils([]);

  return (
    <>
      <ExpandablePanel header="Manage users" loading={loadingUsers}>
        <List
          allowAddItem={admin}
          allowDelete={admin}
          allowEdit
          allowItemButton={editUsers}
          disableDelete={!hasChecks}
          edit={editUsers}
          getListItemCheckboxProps={(key, { userName }) => ({
            disabled: userName === 'admin',
          })}
          header
          listEmpty={<MessageBox {...listMessage} />}
          listItems={users}
          loading={loadingUsers}
          onAdd={() => {
            addDialogRef.current?.setOpen(true);
          }}
          onDelete={() => {
            confirm.setConfirmDialogProps(
              buildDeleteDialogProps({
                getConfirmDialogTitle: (count) =>
                  `Delete the following ${count} users?`,
                onProceedAppend: () => {
                  deleteUtils.submitForm({
                    body: { uuids: checks },
                    getErrorMsg: (parentMsg) => {
                      confirm.finishConfirm('Error', {
                        children: `Failed to delete user(s). ${parentMsg}`,
                      });

                      return null;
                    },
                    method: 'delete',
                    onSuccess: () => {
                      resetChecks();

                      getUsers();

                      confirm.setConfirmDialogOpen(false);
                    },
                    url: '/user',
                  });
                },
                renderEntry: ({ key }) => (
                  <BodyText>{users?.[key].userName}</BodyText>
                ),
              }),
            );

            confirm.setConfirmDialogOpen(true);
          }}
          onEdit={() => {
            setEditUsers((previous) => !previous);
          }}
          onItemCheckboxChange={(key, event, checked) => {
            setCheck(key, checked);
          }}
          onItemClick={(value) => {
            setEditUuid(value.userUUID);

            editDialogRef.current?.setOpen(true);
          }}
          renderListItemCheckboxState={(key) => getCheck(key)}
          renderListItem={(userUUID, { userName }) => (
            <BodyText>{userName}</BodyText>
          )}
        />
      </ExpandablePanel>
      <DialogWithHeader
        header="Add a web interface user"
        loading={loadingUsers}
        ref={addDialogRef}
        showClose
        wide
      >
        {users && (
          <UserForm
            config={{
              initialValues: getUserFormikInitialValues(),
              onSubmit: (values, helpers) => {
                const {
                  [INPUT_ID_USER_NAME]: name,
                  [INPUT_ID_USER_PASSWORD]: password = '',
                } = values;

                handleFormSubmit({
                  confirm,
                  getRequestBody: (): CreateOrUpdateUserRequestBody => ({
                    password,
                    userName: name,
                  }),
                  getSummary: () => ({
                    name,
                    password,
                  }),
                  header: `Add the following new user?`,
                  helpers,
                  onError: () => `Add user failed.`,
                  onSuccess: () => {
                    getUsers();

                    addDialogRef.current?.setOpen(false);

                    return `Created user ${name}.`;
                  },
                  operation: 'add',
                  slotProps: {
                    summary: {
                      hasPassword: true,
                    },
                  },
                  url: `/user`,
                  values,
                });
              },
              validationSchema: buildUserSchema(users),
            }}
            operation="add"
          >
            <UserInputGroup />
          </UserForm>
        )}
      </DialogWithHeader>
      <DialogWithHeader
        header={editTarget && `Update user ${editTarget.userName}`}
        loading={loadingUsers}
        ref={editDialogRef}
        showClose
        wide
      >
        {users && editTarget && (
          <UserForm
            config={{
              initialValues: getUserFormikInitialValues(editTarget),
              onSubmit: (values, helpers) => {
                const {
                  [INPUT_ID_USER_NAME]: name,
                  [INPUT_ID_USER_PASSWORD]: password = '',
                } = values;

                handleFormSubmit({
                  confirm,
                  getRequestBody: (): CreateOrUpdateUserRequestBody => ({
                    password,
                    userName: name,
                  }),
                  getSummary: () => ({
                    name,
                    password,
                  }),
                  header: `Update user ${editTarget.userName} with the following?`,
                  helpers,
                  onError: () => `Update user failed.`,
                  onSuccess: () => {
                    getUsers();

                    editDialogRef.current?.setOpen(false);

                    return `Updated user ${editTarget.userName}`;
                  },
                  operation: 'edit',
                  slotProps: {
                    summary: {
                      hasPassword: true,
                    },
                  },
                  url: `/user/${editTarget.userUUID}`,
                  values,
                });
              },
              validationSchema: buildUserSchema(users, editTarget.userUUID),
            }}
            operation="edit"
          >
            <UserInputGroup
              readonlyName={editTarget.userName === 'admin'}
              requirePassword={false}
            />
          </UserForm>
        )}
      </DialogWithHeader>
      {confirm.confirmDialog}
    </>
  );
};

export default ManageUsersForm;
