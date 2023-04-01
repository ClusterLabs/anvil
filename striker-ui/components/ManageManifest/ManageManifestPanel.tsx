import { FC, useCallback, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import AddManifestInputGroup from './AddManifestInputGroup';
import {
  INPUT_ID_AI_DOMAIN,
  INPUT_ID_AI_PREFIX,
  INPUT_ID_AI_SEQUENCE,
} from './AnIdInputGroup';
import {
  INPUT_ID_PREFIX_AN_HOST,
  MAP_TO_AH_INPUT_HANDLER,
} from './AnHostInputGroup';
import {
  INPUT_ID_PREFIX_AN_NETWORK,
  MAP_TO_AN_INPUT_HANDLER,
} from './AnNetworkInputGroup';
import {
  INPUT_ID_ANC_DNS,
  INPUT_ID_ANC_MTU,
  INPUT_ID_ANC_NTP,
} from './AnNetworkConfigInputGroup';
import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import EditManifestInputGroup from './EditManifestInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import List from '../List';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import RunManifestInputGroup, {
  buildInputIdRMHost,
  INPUT_ID_RM_AN_CONFIRM_PASSWORD,
  INPUT_ID_RM_AN_DESCRIPTION,
  INPUT_ID_RM_AN_PASSWORD,
} from './RunManifestInputGroup';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFormUtils from '../../hooks/useFormUtils';
import useIsFirstRender from '../../hooks/useIsFirstRender';
import useProtectedState from '../../hooks/useProtectedState';

const getFormData = (
  ...[{ target }]: DivFormEventHandlerParameters
): APIBuildManifestRequestBody => {
  const { elements } = target as HTMLFormElement;

  const { value: domain } = elements.namedItem(
    INPUT_ID_AI_DOMAIN,
  ) as HTMLInputElement;
  const { value: prefix } = elements.namedItem(
    INPUT_ID_AI_PREFIX,
  ) as HTMLInputElement;
  const { value: rawSequence } = elements.namedItem(
    INPUT_ID_AI_SEQUENCE,
  ) as HTMLInputElement;
  const { value: dnsCsv } = elements.namedItem(
    INPUT_ID_ANC_DNS,
  ) as HTMLInputElement;
  const { value: rawMtu } = elements.namedItem(
    INPUT_ID_ANC_MTU,
  ) as HTMLInputElement;
  const { value: ntpCsv } = elements.namedItem(
    INPUT_ID_ANC_NTP,
  ) as HTMLInputElement;

  const mtu = Number.parseInt(rawMtu, 10);
  const sequence = Number.parseInt(rawSequence, 10);

  return Object.values(elements).reduce<APIBuildManifestRequestBody>(
    (previous, element) => {
      const { id: inputId } = element;

      if (RegExp(`^${INPUT_ID_PREFIX_AN_HOST}`).test(inputId)) {
        const input = element as HTMLInputElement;

        const {
          dataset: { handler: key = '' },
        } = input;

        MAP_TO_AH_INPUT_HANDLER[key]?.call(null, previous, input);
      } else if (RegExp(`^${INPUT_ID_PREFIX_AN_NETWORK}`).test(inputId)) {
        const input = element as HTMLInputElement;

        const {
          dataset: { handler: key = '' },
        } = input;

        MAP_TO_AN_INPUT_HANDLER[key]?.call(null, previous, input);
      }

      return previous;
    },
    {
      domain,
      hostConfig: { hosts: {} },
      networkConfig: {
        dnsCsv,
        mtu,
        networks: {},
        ntpCsv,
      },
      prefix,
      sequence,
    },
  );
};

const getRunFormData = (
  mdetailHosts: ManifestHostList,
  ...[{ target }]: DivFormEventHandlerParameters
): APIRunManifestRequestBody => {
  const { elements } = target as HTMLFormElement;

  const { value: description } = elements.namedItem(
    INPUT_ID_RM_AN_DESCRIPTION,
  ) as HTMLInputElement;
  const { value: password } = elements.namedItem(
    INPUT_ID_RM_AN_PASSWORD,
  ) as HTMLInputElement;

  const hosts = Object.entries(mdetailHosts).reduce<
    APIRunManifestRequestBody['hosts']
  >((previous, [hostId, { hostNumber, hostType }]) => {
    const inputId = buildInputIdRMHost(hostId);
    const { value: hostUuid } = elements.namedItem(inputId) as HTMLInputElement;

    previous[hostId] = { hostNumber, hostType, hostUuid };

    return previous;
  }, {});

  return { description, hosts, password };
};

const ManageManifestPanel: FC = () => {
  const isFirstRender = useIsFirstRender();

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const addManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>(
    {},
  );
  const runManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps] = useConfirmDialogProps();

  const [hostOverviews, setHostOverviews] = useProtectedState<
    APIHostOverviewList | undefined
  >(undefined);
  const [isEditManifests, setIsEditManifests] = useState<boolean>(false);
  const [isLoadingHostOverviews, setIsLoadingHostOverviews] =
    useState<boolean>(true);
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
      INPUT_ID_AI_DOMAIN,
      INPUT_ID_AI_PREFIX,
      INPUT_ID_AI_SEQUENCE,
      INPUT_ID_ANC_DNS,
      INPUT_ID_ANC_MTU,
      INPUT_ID_ANC_NTP,
    ],
    messageGroupRef,
  );
  const { isFormInvalid } = formUtils;

  const runFormUtils = useFormUtils(
    [
      INPUT_ID_RM_AN_CONFIRM_PASSWORD,
      INPUT_ID_RM_AN_DESCRIPTION,
      INPUT_ID_RM_AN_PASSWORD,
    ],
    messageGroupRef,
  );
  const { isFormInvalid: isRunFormInvalid } = runFormUtils;

  const {
    domain: mdetailDomain,
    hostConfig: { hosts: mdetailHosts = {} } = {},
    name: mdetailName,
    prefix: mdetailPrefix,
    sequence: mdetailSequence,
  } = useMemo<Partial<APIManifestDetail>>(
    () => manifestDetail ?? {},
    [manifestDetail],
  );
  const { fences: knownFences, upses: knownUpses } = useMemo<
    Partial<APIManifestTemplate>
  >(() => manifestTemplate ?? {}, [manifestTemplate]);

  const addManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: (
        <AddManifestInputGroup
          formUtils={formUtils}
          knownFences={knownFences}
          knownUpses={knownUpses}
          previous={{
            domain: mdetailDomain,
            prefix: mdetailPrefix,
            sequence: mdetailSequence,
          }}
        />
      ),
      onSubmitAppend: (...args) => {
        getFormData(...args);
      },
      titleText: 'Add an install manifest',
    }),
    [
      mdetailDomain,
      formUtils,
      knownFences,
      knownUpses,
      mdetailPrefix,
      mdetailSequence,
    ],
  );

  const editManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Edit',
      content: (
        <EditManifestInputGroup
          formUtils={formUtils}
          knownFences={knownFences}
          knownUpses={knownUpses}
          previous={manifestDetail}
        />
      ),
      onSubmitAppend: (...args) => {
        getFormData(...args);
      },
      loading: isLoadingManifestDetail,
      titleText: `Update install manifest ${mdetailName}`,
    }),
    [
      formUtils,
      isLoadingManifestDetail,
      knownFences,
      knownUpses,
      mdetailName,
      manifestDetail,
    ],
  );

  const runManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Run',
      content: (
        <RunManifestInputGroup
          formUtils={runFormUtils}
          knownFences={knownFences}
          knownHosts={hostOverviews}
          knownUpses={knownUpses}
          previous={manifestDetail}
        />
      ),
      loading: isLoadingManifestDetail,
      onSubmitAppend: (...args) => {
        getRunFormData(mdetailHosts, ...args);
      },
      titleText: `Run install manifest ${mdetailName}`,
    }),
    [
      mdetailName,
      hostOverviews,
      mdetailHosts,
      isLoadingManifestDetail,
      knownFences,
      knownUpses,
      manifestDetail,
      runFormUtils,
    ],
  );

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
            <IconButton
              disabled={isEditManifests}
              mapPreset="play"
              onClick={() => {
                setManifestDetail({
                  name: manifestName,
                  uuid: manifestUUID,
                } as APIManifestDetail);
                runManifestFormDialogRef.current.setOpen?.call(null, true);
                getManifestDetail(manifestUUID);
              }}
              variant="normal"
            />
            <BodyText>{manifestName}</BodyText>
          </FlexBox>
        )}
      />
    ),
    [getManifestDetail, isEditManifests, manifestOverviews, setManifestDetail],
  );

  const panelContent = useMemo(
    () =>
      isLoadingHostOverviews ||
      isLoadingManifestTemplate ||
      isLoadingManifestOverviews ? (
        <Spinner />
      ) : (
        listElement
      ),
    [
      isLoadingHostOverviews,
      isLoadingManifestOverviews,
      isLoadingManifestTemplate,
      listElement,
    ],
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

    api
      .get<APIHostOverviewList>('/host', { params: { types: 'node' } })
      .then(({ data }) => {
        setHostOverviews(data);
      })
      .catch((apiError) => {
        handleAPIError(apiError);
      })
      .finally(() => {
        setIsLoadingHostOverviews(false);
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
        preActionArea={messageArea}
        ref={addManifestFormDialogRef}
        scrollContent
      />
      <FormDialog
        {...editManifestFormDialogProps}
        disableProceed={isFormInvalid}
        preActionArea={messageArea}
        ref={editManifestFormDialogRef}
        scrollContent
      />
      <FormDialog
        {...runManifestFormDialogProps}
        disableProceed={isRunFormInvalid}
        preActionArea={messageArea}
        ref={runManifestFormDialogRef}
        scrollContent
      />
      <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />
    </>
  );
};

export default ManageManifestPanel;