import { FC, useMemo, useRef } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import Divider from '../Divider';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import Link from '../Link';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import { BodyText } from '../Text';
import useProtect from '../../hooks/useProtect';
import useProtectedState from '../../hooks/useProtectedState';

const ManageChangedSSHKeysForm: FC<ManageChangedSSHKeysFormProps> = ({
  mitmExternalHref = 'https://en.wikipedia.org/wiki/Man-in-the-middle_attack',
  refreshInterval = 60000,
}) => {
  const { protect } = useProtect();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const listRef = useRef<ListForwardedRefContent>({});

  const [apiMessage, setAPIMessage] = useProtectedState<Message | undefined>(
    undefined,
    protect,
  );
  const [changedSSHKeys, setChangedSSHKeys] = useProtectedState<ChangedSSHKeys>(
    {},
    protect,
  );
  const [confirmDialogProps, setConfirmDialogProps] =
    useProtectedState<ConfirmDialogProps>(
      {
        actionProceedText: '',
        content: '',
        titleText: '',
      },
      protect,
    );

  const apiMessageElement = useMemo(
    () => apiMessage && <MessageBox {...apiMessage} />,
    [apiMessage],
  );
  const isAllowCheckAll = useMemo(
    () => Object.keys(changedSSHKeys).length > 1,
    [changedSSHKeys],
  );

  const { isLoading } = periodicFetch<APISSHKeyConflictOverviewList>(
    `${API_BASE_URL}/ssh-key/conflict`,
    {
      onError: (error) => {
        setAPIMessage({
          children: `Failed to fetch SSH key conflicts. Error: ${error}`,
          type: 'error',
        });
      },
      onSuccess: (data) => {
        setChangedSSHKeys((previous) =>
          Object.values(data).reduce<ChangedSSHKeys>((nyu, stateList) => {
            Object.values(stateList).forEach(
              ({ hostName, hostUUID, ipAddress, stateUUID }) => {
                nyu[stateUUID] = {
                  ...previous[stateUUID],
                  hostName,
                  hostUUID,
                  ipAddress,
                };
              },
            );

            return nyu;
          }, {}),
        );
      },
      refreshInterval,
    },
  );

  return (
    <>
      <ExpandablePanel
        header={<BodyText>Manage changed SSH keys</BodyText>}
        loading={isLoading}
      >
        <FlexBox spacing=".2em">
          <BodyText>
            The identity of the following targets have unexpectedly changed.
          </BodyText>
          <MessageBox type="warning" isAllowClose>
            If you haven&apos;t rebuilt the listed targets, then you could be
            experiencing a{' '}
            <Link
              href={mitmExternalHref}
              sx={{ display: 'inline-flex' }}
              target="_blank"
            >
              &quot;Man In The Middle&quot;
            </Link>{' '}
            attack. Please verify the targets have changed for a known reason
            before proceeding to remove the broken keys.
          </MessageBox>
          <List
            header={
              <FlexBox
                row
                spacing=".3em"
                sx={{
                  width: '100%',

                  '& > :not(:last-child)': {
                    display: { xs: 'none', sm: 'flex' },
                  },

                  '& > :last-child': {
                    display: { xs: 'initial', sm: 'none' },
                    marginLeft: 0,
                  },
                }}
              >
                <FlexBox
                  row
                  spacing=".3em"
                  sx={{ flexBasis: 'calc(50% + 1em)' }}
                >
                  <BodyText>Host name</BodyText>
                  <Divider sx={{ flexGrow: 1 }} />
                </FlexBox>
                <FlexBox row spacing=".3em" sx={{ flexGrow: 1 }}>
                  <BodyText>IP address</BodyText>
                  <Divider sx={{ flexGrow: 1 }} />
                </FlexBox>
                <Divider sx={{ flexGrow: 1 }} />
              </FlexBox>
            }
            allowCheckAll={isAllowCheckAll}
            allowCheckItem
            allowDelete
            allowEdit={false}
            edit
            listEmpty={
              <BodyText align="center">No conflicting keys found.</BodyText>
            }
            listItems={changedSSHKeys}
            onAllCheckboxChange={(event, isChecked) => {
              Object.keys(changedSSHKeys).forEach((key) => {
                changedSSHKeys[key].isChecked = isChecked;
              });

              setChangedSSHKeys((previous) => ({ ...previous }));
            }}
            onDelete={() => {
              let deleteCount = 0;

              const deleteRequestBody = Object.entries(changedSSHKeys).reduce<{
                [hostUUID: string]: string[];
              }>((previous, [stateUUID, { hostUUID, isChecked }]) => {
                if (isChecked) {
                  if (!previous[hostUUID]) {
                    previous[hostUUID] = [];
                  }

                  previous[hostUUID].push(stateUUID);

                  deleteCount += 1;
                }

                return previous;
              }, {});

              setConfirmDialogProps({
                actionProceedText: 'Delete',
                content: `Resolve ${deleteCount} SSH key conflicts. Please make sure the identity change(s) are expected to avoid MITM attacks.`,
                onProceedAppend: () => {
                  api
                    .delete('/ssh-key/conflict', { data: deleteRequestBody })
                    .catch((error) => {
                      const emsg = handleAPIError(error);

                      emsg.children = `Failed to delete selected SSH key conflicts. ${emsg.children}`;

                      setAPIMessage(emsg);
                    });
                },
                proceedColour: 'red',
                titleText: `Delete ${deleteCount} conflicting SSH keys?`,
              });

              confirmDialogRef.current.setOpen?.call(null, true);
            }}
            onItemCheckboxChange={(key, event, isChecked) => {
              changedSSHKeys[key].isChecked = isChecked;

              listRef.current.setCheckAll?.call(
                null,
                Object.values(changedSSHKeys).every(
                  ({ isChecked: isItemChecked }) => isItemChecked,
                ),
              );

              setChangedSSHKeys((previous) => ({ ...previous }));
            }}
            renderListItem={(hostUUID, { hostName, ipAddress }) => (
              <FlexBox
                spacing={0}
                sm="row"
                sx={{ width: '100%', '& > *': { flexBasis: '50%' } }}
                xs="column"
              >
                <BodyText>{hostName}</BodyText>
                <BodyText>{ipAddress}</BodyText>
              </FlexBox>
            )}
            renderListItemCheckboxState={(key, { isChecked }) =>
              isChecked === true
            }
            ref={listRef}
          />
        </FlexBox>
        {apiMessageElement}
      </ExpandablePanel>
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageChangedSSHKeysForm;
