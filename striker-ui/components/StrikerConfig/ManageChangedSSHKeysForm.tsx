import { Box } from '@mui/material';
import { FC, useMemo, useState } from 'react';

import api from '../../lib/api';
import FlexBox from '../FlexBox';
import handleAPIError from '../../lib/handleAPIError';
import Link from '../Link';
import List from '../List';
import MessageBox, { Message } from '../MessageBox';
import { ExpandablePanel } from '../Panels';
import { BodyText, SmallText } from '../Text';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';

const ManageChangedSSHKeysForm: FC<ManageChangedSSHKeysFormProps> = ({
  mitmExternalHref = 'https://en.wikipedia.org/wiki/Man-in-the-middle_attack',
  refreshInterval = 10000,
}) => {
  const [apiMessage, setApiMessage] = useState<Message | undefined>();

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog();

  const apiMessageElement = useMemo(
    () => apiMessage && <MessageBox {...apiMessage} />,
    [apiMessage],
  );

  const { data: changedKeys, loading } =
    useFetch<APISSHKeyConflictOverviewList>(`/ssh-key/conflict`, {
      onError: (error) => {
        const emsg = handleAPIError(error);

        emsg.children = <>Failed to fetch SSH key conflicts. {emsg.children}</>;

        setApiMessage(emsg);
      },
      onSuccess: () => {
        setApiMessage(undefined);
      },
      refreshInterval,
    });

  const { checks, getCheck, hasAllChecks, hasChecks, setAllChecks, setCheck } =
    useChecklist({ list: changedKeys });

  const isAllowCheckAll = useMemo(
    () => changedKeys && Object.keys(changedKeys).length > 1,
    [changedKeys],
  );

  return (
    <>
      <ExpandablePanel header="Manage changed SSH keys" loading={loading}>
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
            header
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
            listItems={changedKeys}
            onAllCheckboxChange={(event, checked) => {
              setAllChecks(checked);
            }}
            onDelete={() => {
              if (!changedKeys) return;

              const deleteRequestBody = {
                badKeys: checks,
              };

              setConfirmDialogProps({
                actionProceedText: 'Delete',
                content: `Resolves ${checks.length} SSH key conflicts. Please make sure the identity change(s) are expected to avoid MITM attacks.`,
                onProceedAppend: () => {
                  setConfirmDialogLoading(true);

                  api
                    .delete('/ssh-key/conflict', {
                      data: deleteRequestBody,
                    })
                    .then(() => {
                      finishConfirm('Success', {
                        children: <>Started job to delete the selected keys.</>,
                      });
                    })
                    .catch((error) => {
                      const emsg = handleAPIError(error);

                      emsg.children = (
                        <>Failed to delete the selected keys. {emsg.children}</>
                      );

                      finishConfirm('Error', emsg);
                    });
                },
                proceedColour: 'red',
                titleText: `Delete ${checks.length} conflicting SSH keys?`,
              });

              setConfirmDialogOpen(true);
            }}
            onItemCheckboxChange={(key, event, checked) => {
              setCheck(key, checked);
            }}
            renderListItem={(badKey, value) => {
              const { ip, name, short } = value.target;

              return (
                <Box width="calc(100% - 4em)">
                  <BodyText noWrap>{short || name || ip}</BodyText>
                  <SmallText monospaced noWrap>
                    {badKey}
                  </SmallText>
                </Box>
              );
            }}
            renderListItemCheckboxState={(key) => getCheck(key)}
          />
        </FlexBox>
        {apiMessageElement}
      </ExpandablePanel>
      {confirmDialog}
    </>
  );
};

export default ManageChangedSSHKeysForm;
