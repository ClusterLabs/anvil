import { FC, useMemo, useRef, useState } from 'react';

import CommonUserInputGroup, {
  INPUT_ID_USER_CONFIRM_PASSWORD,
  INPUT_ID_USER_NAME,
  INPUT_ID_USER_PASSWORD,
} from './CommonUserInputGroup';
import ConfirmDialog from '../ConfirmDialog';
import FormDialog from '../FormDialog';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { ExpandablePanel } from '../Panels';
import { BodyText } from '../Text';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';

const getFormEntries = (
  ...[{ target }]: DivFormEventHandlerParameters
): CreateUserRequestBody => {
  const { elements } = target as HTMLFormElement;

  const { value: userName } = elements.namedItem(
    INPUT_ID_USER_NAME,
  ) as HTMLInputElement;

  const inputUserPassword = elements.namedItem(INPUT_ID_USER_PASSWORD);

  let password = '';

  if (inputUserPassword) {
    ({ value: password } = inputUserPassword as HTMLInputElement);
  }

  return { password, userName };
};

const ManageUsersForm: FC = () => {
  const addUserFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editUserFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();

  const [editUsers, setEditUsers] = useState<boolean>(false);
  const [listMessage, setListMessage] = useState<Message>({
    children: `No users found.`,
  });
  const [userDetail, setUserDetail] = useState<
    UserOverviewMetadata | undefined
  >();

  const { data: users, loading: loadingUsers } =
    useFetch<UserOverviewMetadataList>(`/user`, {
      onError: (error) => {
        setListMessage(handleAPIError(error));
      },
      periodic: true,
    });

  const formUtils = useFormUtils(
    [
      INPUT_ID_USER_CONFIRM_PASSWORD,
      INPUT_ID_USER_NAME,
      INPUT_ID_USER_PASSWORD,
    ],
    messageGroupRef,
  );
  const { isFormInvalid, isFormSubmitting, submitForm } = formUtils;

  const { buildDeleteDialogProps, checks, getCheck, hasChecks, setCheck } =
    useChecklist({ list: users });

  const { userName: udetailName, userUUID: udetailUuid } = useMemo<
    Partial<UserOverviewMetadata>
  >(() => userDetail ?? {}, [userDetail]);

  const addUserFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: (
        <CommonUserInputGroup
          formUtils={formUtils}
          requirePassword
          showPasswordField
        />
      ),
      onSubmitAppend: (...args) => {
        const body = getFormEntries(...args);

        setConfirmDialogProps({
          actionProceedText: 'Add',
          content: <FormSummary entries={body} hasPassword />,
          onProceedAppend: () => {
            submitForm({
              body,
              getErrorMsg: (parentMsg) => <>Add user failed. {parentMsg}</>,
              method: 'post',
              successMsg: `Created user ${body.userName}.`,
              url: '/user',
            });
          },
          titleText: `Add the following new user?`,
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      titleText: 'Add a web interface user',
    }),
    [formUtils, setConfirmDialogProps, submitForm],
  );

  const editUserFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Edit',
      content: (
        <CommonUserInputGroup
          formUtils={formUtils}
          previous={{ name: udetailName }}
          readOnlyUserName={udetailName === 'admin'}
          showPasswordField
        />
      ),
      onSubmitAppend: (...args) => {
        const body = getFormEntries(...args);

        setConfirmDialogProps({
          actionProceedText: 'Update',
          content: <FormSummary entries={body} hasPassword />,
          onProceedAppend: () => {
            submitForm({
              body,
              getErrorMsg: (parentMsg) => <>Update user failed. {parentMsg}</>,
              method: 'put',
              successMsg: `Updated user ${udetailName}`,
              url: `/user/${udetailUuid}`,
            });
          },
          titleText: `Update user ${udetailName} with the following?`,
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      titleText: `Edit user ${udetailName}`,
    }),
    [formUtils, setConfirmDialogProps, submitForm, udetailName, udetailUuid],
  );

  const messageArea = useMemo(
    () => (
      <MessageGroup
        count={1}
        defaultMessageType="warning"
        ref={messageGroupRef}
      />
    ),
    [],
  );

  const allowModOthers = useMemo<boolean>(
    () => users?.current?.userName === 'admin',
    [users],
  );

  return (
    <>
      <ExpandablePanel header="Manage users" loading={loadingUsers}>
        <List
          allowAddItem={allowModOthers}
          allowDelete={allowModOthers}
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
          onAdd={() => {
            addUserFormDialogRef.current.setOpen?.call(null, true);
          }}
          onDelete={() => {
            setConfirmDialogProps(
              buildDeleteDialogProps({
                confirmDialogProps: {
                  onProceedAppend: () => {
                    submitForm({
                      body: { uuids: checks },
                      getErrorMsg: (parentMsg) => (
                        <>Delete user(s) failed. {parentMsg}</>
                      ),
                      method: 'delete',
                      url: '/user',
                    });
                  },
                },
                formSummaryProps: {
                  renderEntry: ({ key }) => (
                    <BodyText>{users?.[key].userName}</BodyText>
                  ),
                },
                getConfirmDialogTitle: (length) =>
                  `Delete the following ${length} users?`,
              }),
            );

            confirmDialogRef.current.setOpen?.call(null, true);
          }}
          onEdit={() => setEditUsers((previous) => !previous)}
          onItemCheckboxChange={(key, event, checked) => setCheck(key, checked)}
          onItemClick={(value) => {
            if (editUsers) {
              setUserDetail(value);
              editUserFormDialogRef.current.setOpen?.call(null, true);
            }
          }}
          renderListItemCheckboxState={(key) => getCheck(key)}
          renderListItem={(userUUID, { userName }) => (
            <BodyText>{userName}</BodyText>
          )}
        />
      </ExpandablePanel>
      <FormDialog
        {...addUserFormDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={addUserFormDialogRef}
      />
      <FormDialog
        {...editUserFormDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={editUserFormDialogRef}
      />
      <ConfirmDialog
        closeOnProceed
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageUsersForm;
