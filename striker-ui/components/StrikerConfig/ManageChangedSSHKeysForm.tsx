import { FC, useMemo, useRef } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import Divider from '../Divider';
import FlexBox from '../FlexBox';
import Link from '../Link';
import List from '../List';
import MessageBox from '../MessageBox';
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

  const listRef = useRef<ListForwardedRefContent>({});

  const [changedSSHKeys, setChangedSSHKeys] = useProtectedState<ChangedSSHKeys>(
    {},
    protect,
  );

  const isAllowCheckAll = useMemo(
    () => Object.keys(changedSSHKeys).length > 1,
    [changedSSHKeys],
  );

  const { isLoading } = periodicFetch<APISSHKeyConflictOverviewList>(
    `${API_BASE_URL}/ssh-key/conflict`,
    {
      refreshInterval,
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
    },
  );

  return (
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
          experiencing a &quot;
          <Link
            href={mitmExternalHref}
            sx={{ display: 'inline-flex' }}
            target="_blank"
          >
            Man In The Middle
          </Link>
          &quot; attack. Please verify the targets have changed for a known
          reason before proceeding to remove the broken keys.
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
              <FlexBox row spacing=".3em" sx={{ flexBasis: 'calc(50% + 1em)' }}>
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
    </ExpandablePanel>
  );
};

export default ManageChangedSSHKeysForm;
