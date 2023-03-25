import { PlayCircle } from '@mui/icons-material';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

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
import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import EditManifestInputGroup from './EditManifestInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import List from '../List';
import { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFormUtils from '../../hooks/useFormUtils';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtectedState from '../../hooks/useProtectedState';

const ManageManifestPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const addManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>(
    {},
  );
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps] = useConfirmDialogProps();

  const [isEditManifests, setIsEditManifests] = useState<boolean>(false);
  const [isLoadingManifestDetail, setIsLoadingManifestDetail] =
    useProtectedState<boolean>(true);
  const [isLoadingManifestTemplate, setIsLoadingManifestTemplate] =
    useState<boolean>(true);
  const [manifestDetail, setManifestDetail] = useProtectedState<
    APIManifestDetail | undefined
  >(undefined);
  const [manifestTemplate, setManifestTemplate] = useProtectedState<
    APIManifestTemplate | undefined
  >(undefined);

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

  const addManifestFormDialogProps = useMemo<ConfirmDialogProps>(() => {
    let domain: string | undefined;
    let prefix: string | undefined;
    let sequence: number | undefined;
    let fences: APIManifestTemplateFenceList | undefined;
    let upses: APIManifestTemplateUpsList | undefined;

    if (manifestTemplate) {
      ({ domain, fences, prefix, sequence, upses } = manifestTemplate);
    }

    return {
      actionProceedText: 'Add',
      content: (
        <AddManifestInputGroup
          formUtils={formUtils}
          knownFences={fences}
          knownUpses={upses}
          previous={{ domain, prefix, sequence }}
        />
      ),
      titleText: 'Add an install manifest',
    };
  }, [formUtils, manifestTemplate]);

  const editManifestFormDialogProps = useMemo<ConfirmDialogProps>(() => {
    let fences: APIManifestTemplateFenceList | undefined;
    let manifestName: string | undefined;
    let upses: APIManifestTemplateUpsList | undefined;

    if (manifestTemplate) {
      ({ fences, upses } = manifestTemplate);
    }

    if (manifestDetail) {
      ({ name: manifestName } = manifestDetail);
    }

    return {
      actionProceedText: 'Edit',
      content: (
        <EditManifestInputGroup
          formUtils={formUtils}
          knownFences={fences}
          knownUpses={upses}
          previous={manifestDetail}
        />
      ),
      loading: isLoadingManifestDetail,
      titleText: `Update install manifest ${manifestName}`,
    };
  }, [formUtils, isLoadingManifestDetail, manifestDetail, manifestTemplate]);

  const getManifestDetail = useCallback(
    (manifestUuid: string, finallyAppend?: () => void) => {
      setIsLoadingManifestDetail(true);

      api
        .get<APIManifestDetail>(`manifest/${manifestUuid}`)
        .then(({ data }) => {
          data.uuid = manifestUuid;

          setManifestDetail(data);
        })
        .catch((error) => {
          handleAPIError(error);
        })
        .finally(() => {
          setIsLoadingManifestDetail(false);
          finallyAppend?.call(null);
        });
    },
    [setIsLoadingManifestDetail, setManifestDetail],
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
          addManifestFormDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditManifests((previous) => !previous);
        }}
        onItemClick={({ manifestName, manifestUUID }) => {
          setManifestDetail({
            name: manifestName,
            uuid: manifestUUID,
          } as APIManifestDetail);
          editManifestFormDialogRef.current.setOpen?.call(null, true);
          getManifestDetail(manifestUUID);
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
    [getManifestDetail, isEditManifests, manifestOverviews, setManifestDetail],
  );

  const panelContent = useMemo(
    () =>
      isLoadingManifestTemplate || isLoadingManifestOverviews ? (
        <Spinner />
      ) : (
        listElement
      ),
    [isLoadingManifestOverviews, isLoadingManifestTemplate, listElement],
  );

  if (isFirstRender) {
    api
      .get<APIManifestTemplate>('/manifest/template')
      .then(({ data }) => {
        setManifestTemplate(data);
      })
      .catch((error) => {
        handleAPIError(error);
      })
      .finally(() => {
        setIsLoadingManifestTemplate(false);
      });
  }

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage manifests</HeaderText>
        </PanelHeader>
        {panelContent}
      </Panel>
      <FormDialog
        {...addManifestFormDialogProps}
        disableProceed={isFormInvalid}
        ref={addManifestFormDialogRef}
        scrollContent
      />
      <FormDialog
        {...editManifestFormDialogProps}
        disableProceed={isFormInvalid}
        ref={editManifestFormDialogRef}
        scrollContent
      />
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageManifestPanel;
