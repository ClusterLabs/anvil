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
import useChecklist from '../../hooks/useChecklist';
import useProtectedState from '../../hooks/useProtectedState';

const ManageChangedSSHKeysForm: FC<ManageChangedSSHKeysFormProps> = ({
  mitmExternalHref = 'https://en.wikipedia.org/wiki/Man-in-the-middle_attack',
  refreshInterval = 60000,
}) => {
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});

  const [apiMessage, setAPIMessage] = useProtectedState<Message | undefined>(
    undefined,
  );
  const [changedSSHKeys, setChangedSSHKeys] = useProtectedState<ChangedSSHKeys>(
    {},
  );
  const [confirmDialogProps, setConfirmDialogProps] =
    useProtectedState<ConfirmDialogProps>({
      actionProceedText: '',
      content: '',
      titleText: '',
    });

  const { checks, getCheck, hasAllChecks, hasChecks, setAllChecks, setCheck } =
    useChecklist({ list: changedSSHKeys });

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
      <ExpandablePanel header="Manage changed SSH keys" loading={isLoading}>
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
            disableDelete={!hasChecks}
            edit
            getListCheckboxProps={() => ({
              checked: hasAllChecks,
            })}
            listEmpty={
              <BodyText align="center">No conflicting keys found.</BodyText>
            }
            listItems={changedSSHKeys}
            onAllCheckboxChange={(event, checked) => {
              setAllChecks(checked);
            }}
            onDelete={() => {
              const deleteRequestBody = checks.reduce<{
                [hostUUID: string]: string[];
              }>((previous, stateUUID) => {
                const checked = getCheck(stateUUID);

                if (!checked) return previous;

                const { hostUUID } = changedSSHKeys[stateUUID];

                if (!previous[hostUUID]) {
                  previous[hostUUID] = [];
                }

                previous[hostUUID].push(stateUUID);

                return previous;
              }, {});

              setConfirmDialogProps({
                actionProceedText: 'Delete',
                content: `Resolve ${checks.length} SSH key conflicts. Please make sure the identity change(s) are expected to avoid MITM attacks.`,
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
                titleText: `Delete ${checks.length} conflicting SSH keys?`,
              });

              confirmDialogRef.current.setOpen?.call(null, true);
            }}
            onItemCheckboxChange={(key, event, checked) => {
              setCheck(key, checked);
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
            renderListItemCheckboxState={(key) => getCheck(key)}
          />
        </FlexBox>
        {apiMessageElement}
      </ExpandablePanel>
      <ConfirmDialog
        closeOnProceed
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageChangedSSHKeysForm;
