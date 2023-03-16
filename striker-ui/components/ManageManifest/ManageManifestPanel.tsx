import { PlayCircle } from '@mui/icons-material';
import { FC, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import AddManifestInputGroup from './AddManifestInputGroup';
import {
  INPUT_ID_ANVIL_ID_DOMAIN,
  INPUT_ID_ANVIL_ID_PREFIX,
  INPUT_ID_ANVIL_ID_SEQUENCE,
} from './AnvilIdInputGroup';
import {
  INPUT_ID_ANVIL_NETWORK_CONFIG_DNS,
  INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
  INPUT_ID_ANVIL_NETWORK_CONFIG_NTP,
} from './AnvilNetworkConfigInputGroup';
import ConfirmDialog from '../ConfirmDialog';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import IconButton from '../IconButton';
import List from '../List';
import { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFormUtils from '../../hooks/useFormUtils';

const ManageManifestPanel: FC = () => {
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const formDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps] = useConfirmDialogProps();
  const [formDialogProps, setFormDialogProps] = useConfirmDialogProps();

  const [isEditManifests, setIsEditManifests] = useState<boolean>(false);

  const { data: manifestOverviews, isLoading: isLoadingManifestOverviews } =
    periodicFetch<APIManifestOverviewList>(`${API_BASE_URL}/manifest`, {
      refreshInterval: 60000,
    });

  const formUtils = useFormUtils(
    [
      INPUT_ID_ANVIL_ID_DOMAIN,
      INPUT_ID_ANVIL_ID_PREFIX,
      INPUT_ID_ANVIL_ID_SEQUENCE,
      INPUT_ID_ANVIL_NETWORK_CONFIG_DNS,
      INPUT_ID_ANVIL_NETWORK_CONFIG_MTU,
      INPUT_ID_ANVIL_NETWORK_CONFIG_NTP,
    ],
    messageGroupRef,
  );
  const { isFormInvalid } = formUtils;

  const addAnvilManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: <AddManifestInputGroup formUtils={formUtils} />,
      titleText: 'Add a Anvil! manifest',
    }),
    [formUtils],
  );

  const listElement = useMemo(
    () => (
      <List
        allowEdit
        allowItemButton={isEditManifests}
        edit={isEditManifests}
        header
        listEmpty="No manifest(s) registered."
        listItems={manifestOverviews}
        onAdd={() => {
          setFormDialogProps(addAnvilManifestFormDialogProps);
          formDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditManifests((previous) => !previous);
        }}
        renderListItem={(manifestUUID, { manifestName }) => (
          <FlexBox fullWidth row>
            <IconButton disabled={isEditManifests} variant="normal">
              <PlayCircle />
            </IconButton>
            <BodyText>{manifestName}</BodyText>
          </FlexBox>
        )}
      />
    ),
    [
      addAnvilManifestFormDialogProps,
      isEditManifests,
      manifestOverviews,
      setFormDialogProps,
    ],
  );

  const panelContent = useMemo(
    () => (isLoadingManifestOverviews ? <Spinner /> : listElement),
    [isLoadingManifestOverviews, listElement],
  );

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage manifests</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <FormDialog
        {...formDialogProps}
        ref={formDialogRef}
        proceedButtonProps={{ disabled: isFormInvalid }}
        scrollBoxProps={{
          paddingRight: '.4em',
          paddingTop: '.6em',
          sx: { overflowX: 'hidden' },
        }}
        scrollContent
      />
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageManifestPanel;
