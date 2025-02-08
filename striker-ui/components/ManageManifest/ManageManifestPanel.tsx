import { FC, useCallback, useMemo, useRef, useState } from 'react';

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
  INPUT_ID_ANC_NTP,
} from './AnNetworkConfigInputGroup';
import api from '../../lib/api';
import ConfirmDialog from '../ConfirmDialog';
import { DialogWithHeader } from '../Dialog';
import EditManifestInputGroup from './EditManifestInputGroup';
import FlexBox from '../FlexBox';
import FormDialog from '../FormDialog';
import FormSummary from '../FormSummary';
import handleAPIError from '../../lib/handleAPIError';
import IconButton from '../IconButton';
import List from '../List';
import MessageBox from '../MessageBox';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import RunManifestForm from './RunManifestForm';
import Spinner from '../Spinner';
import { BodyText, HeaderText } from '../Text';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';

const REQ_BODY_MAX_DEPTH = 6;

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
  const { value: ntpCsv } = elements.namedItem(
    INPUT_ID_ANC_NTP,
  ) as HTMLInputElement;

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
        networks: {},
        ntpCsv,
      },
      prefix,
      sequence,
    },
  );
};

const ManageManifestPanel: FC = () => {
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const addManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editManifestFormDialogRef = useRef<ConfirmDialogForwardedRefContent>(
    {},
  );
  const runDialogRef = useRef<DialogForwardedRefContent>(null);
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [oldConfirmDialogProps, setOldConfirmDialogProps] =
    useConfirmDialogProps();

  const [isEditManifests, setIsEditManifests] = useState<boolean>(false);
  const [isLoadingManifestDetail, setIsLoadingManifestDetail] =
    useState<boolean>(true);
  const [manifestDetail, setManifestDetail] = useState<
    APIManifestDetail | undefined
  >();

  const {
    data: manifestOverviews,
    loading: isLoadingManifestOverviews,
    mutate: getManifestOverviews,
  } = useFetch<APIManifestOverviewList>('/manifest', {
    refreshInterval: 10000,
  });

  const {
    data: manifestTemplate,
    loading: isLoadingManifestTemplate,
    mutate: getManifestTemplate,
  } = useFetch<APIManifestTemplate>('/manifest/template');

  const {
    data: hostOverviews,
    loading: isLoadingHostOverviews,
    mutate: getHostOverviews,
  } = useFetch<APIHostOverviewList>('/host?types=node');

  const formUtils = useFormUtils(
    [
      INPUT_ID_AI_DOMAIN,
      INPUT_ID_AI_PREFIX,
      INPUT_ID_AI_SEQUENCE,
      INPUT_ID_ANC_DNS,
      INPUT_ID_ANC_NTP,
    ],
    messageGroupRef,
  );
  const { isFormInvalid, isFormSubmitting, submitForm } = formUtils;

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasChecks,
    resetChecks,
    setCheck,
  } = useChecklist({
    list: manifestOverviews,
  });

  const { name: mdetailName, uuid: mdetailUuid } = useMemo<
    Partial<APIManifestDetail>
  >(() => manifestDetail ?? {}, [manifestDetail]);
  const {
    domain: mtemplateDomain,
    fences: knownFences,
    prefix: mtemplatePrefix,
    sequence: mtemplateSequence,
    upses: knownUpses,
  } = useMemo<Partial<APIManifestTemplate>>(
    () => manifestTemplate ?? {},
    [manifestTemplate],
  );

  const countHostFences = useCallback(
    (
      body: APIBuildManifestRequestBody,
    ): { counts: Record<string, number>; messages: React.ReactNode[] } => {
      const {
        hostConfig: { hosts },
      } = body;

      const counts = Object.values(hosts).reduce<Record<string, number>>(
        (previous, host) => {
          const { fences, hostType, hostNumber } = host;

          const hostName = `${hostType.replace(
            /node/,
            'subnode',
          )}${hostNumber}`;

          if (!fences) {
            previous[hostName] = 0;

            return previous;
          }

          previous[hostName] = Object.values(fences).reduce<number>(
            (count, fence) => {
              const { fencePort } = fence;

              const diff = fencePort.length ? 1 : 0;

              return count + diff;
            },
            0,
          );

          return previous;
        },
        {},
      );

      const messages = Object.entries(counts).map((entry) => {
        const [hostName, fenceCount] = entry;

        return fenceCount ? (
          <></>
        ) : (
          <MessageBox key={`${hostName}-no-fence-port-message`}>
            No fence device port specified for {hostName}.
          </MessageBox>
        );
      });

      return { counts, messages };
    },
    [],
  );

  const addManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Add',
      content: (
        <AddManifestInputGroup
          formUtils={formUtils}
          knownFences={knownFences}
          knownUpses={knownUpses}
          previous={{
            domain: mtemplateDomain,
            prefix: mtemplatePrefix,
            sequence: mtemplateSequence,
          }}
        />
      ),
      onSubmitAppend: (...args) => {
        const body = getFormData(...args);
        const { messages } = countHostFences(body);

        setOldConfirmDialogProps({
          actionProceedText: 'Add',
          content: <FormSummary entries={body} maxDepth={REQ_BODY_MAX_DEPTH} />,
          onProceedAppend: () => {
            submitForm({
              body,
              getErrorMsg: (parentMsg) => (
                <>Failed to add install manifest. {parentMsg}</>
              ),
              method: 'post',
              onSuccess: () => getManifestOverviews(),
              successMsg: 'Successfully added install manifest',
              url: '/manifest',
            });
          },
          preActionArea: <FlexBox spacing=".3em">{messages}</FlexBox>,
          titleText: `Add install manifest?`,
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      titleText: 'Add an install manifest',
    }),
    [
      countHostFences,
      formUtils,
      getManifestOverviews,
      knownFences,
      knownUpses,
      mtemplateDomain,
      mtemplatePrefix,
      mtemplateSequence,
      setOldConfirmDialogProps,
      submitForm,
    ],
  );

  const editManifestFormDialogProps = useMemo<ConfirmDialogProps>(
    () => ({
      actionProceedText: 'Update',
      content: (
        <EditManifestInputGroup
          formUtils={formUtils}
          knownFences={knownFences}
          knownUpses={knownUpses}
          previous={manifestDetail}
        />
      ),
      onSubmitAppend: (...args) => {
        const body = getFormData(...args);
        const { messages } = countHostFences(body);

        setOldConfirmDialogProps({
          actionProceedText: 'Update',
          content: <FormSummary entries={body} maxDepth={REQ_BODY_MAX_DEPTH} />,
          onProceedAppend: () => {
            submitForm({
              body,
              getErrorMsg: (parentMsg) => (
                <>Failed to update install manifest. {parentMsg}</>
              ),
              method: 'put',
              onSuccess: () => getManifestOverviews(),
              successMsg: `Successfully updated install manifest ${mdetailName}`,
              url: `/manifest/${mdetailUuid}`,
            });
          },
          preActionArea: <FlexBox spacing=".3em">{messages}</FlexBox>,
          titleText: `Update install manifest ${mdetailName}?`,
        });

        confirmDialogRef.current.setOpen?.call(null, true);
      },
      loading: isLoadingManifestDetail,
      titleText: `Update install manifest ${mdetailName}`,
    }),
    [
      countHostFences,
      formUtils,
      getManifestOverviews,
      isLoadingManifestDetail,
      knownFences,
      knownUpses,
      manifestDetail,
      mdetailName,
      mdetailUuid,
      setOldConfirmDialogProps,
      submitForm,
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
        disableDelete={!hasChecks}
        edit={isEditManifests}
        header
        listEmpty="No manifest(s) registered."
        listItems={manifestOverviews}
        onAdd={() => {
          addManifestFormDialogRef.current.setOpen?.call(null, true);
        }}
        onDelete={() => {
          setOldConfirmDialogProps(
            buildDeleteDialogProps({
              onProceedAppend: () => {
                submitForm({
                  body: { uuids: checks },
                  getErrorMsg: (parentMsg) => (
                    <>Delete manifest(s) failed. {parentMsg}</>
                  ),
                  method: 'delete',
                  onSuccess: () => {
                    getManifestOverviews();
                    resetChecks();
                  },
                  url: `/manifest`,
                });
              },
              getConfirmDialogTitle: (count) => `Delete ${count} manifest(s)?`,
              renderEntry: ({ key }) => (
                <BodyText>{manifestOverviews?.[key].manifestName}</BodyText>
              ),
            }),
          );

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setIsEditManifests((previous) => !previous);
        }}
        onItemCheckboxChange={(key, event, checked) => {
          setCheck(key, checked);
        }}
        onItemClick={({ manifestName, manifestUUID }) => {
          setManifestDetail({
            name: manifestName,
            uuid: manifestUUID,
          } as APIManifestDetail);
          editManifestFormDialogRef.current.setOpen?.call(null, true);
          getManifestDetail(manifestUUID);
        }}
        renderListItemCheckboxState={(key) => getCheck(key)}
        renderListItem={(manifestUUID, { manifestName }) => (
          <FlexBox fullWidth row>
            <IconButton
              disabled={isEditManifests}
              mapPreset="play"
              onClick={() => {
                runDialogRef.current?.setOpen(true);
                getManifestDetail(manifestUUID);
              }}
              variant="normal"
            />
            <BodyText>{manifestName}</BodyText>
          </FlexBox>
        )}
      />
    ),
    [
      buildDeleteDialogProps,
      checks,
      getCheck,
      getManifestDetail,
      getManifestOverviews,
      hasChecks,
      isEditManifests,
      manifestOverviews,
      resetChecks,
      setCheck,
      setOldConfirmDialogProps,
      setManifestDetail,
      submitForm,
    ],
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

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog({
    initial: {
      scrollContent: true,
      wide: true,
    },
  });

  const formTools = useMemo<CrudListFormTools>(
    () => ({
      add: { open: () => null },
      confirm: {
        finish: finishConfirm,
        loading: setConfirmDialogLoading,
        open: (v = true) => setConfirmDialogOpen(v),
        prepare: setConfirmDialogProps,
      },
      edit: {
        open: (v = true) => runDialogRef?.current?.setOpen(v),
      },
    }),
    [
      finishConfirm,
      setConfirmDialogLoading,
      setConfirmDialogOpen,
      setConfirmDialogProps,
    ],
  );

  const loadingRunForm = useMemo<boolean>(
    () =>
      isLoadingManifestTemplate ||
      isLoadingManifestDetail ||
      isLoadingHostOverviews,
    [
      isLoadingHostOverviews,
      isLoadingManifestDetail,
      isLoadingManifestTemplate,
    ],
  );

  const runForm = useMemo<React.ReactNode>(
    () =>
      manifestDetail &&
      knownFences &&
      hostOverviews &&
      knownUpses && (
        <RunManifestForm
          detail={manifestDetail}
          knownFences={knownFences}
          knownHosts={hostOverviews}
          knownUpses={knownUpses}
          onSubmitSuccess={() => {
            getManifestTemplate();
            getHostOverviews();
          }}
          tools={formTools}
        />
      ),
    [
      formTools,
      getHostOverviews,
      getManifestTemplate,
      hostOverviews,
      knownFences,
      knownUpses,
      manifestDetail,
    ],
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
        {...addManifestFormDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={addManifestFormDialogRef}
        scrollContent
        showClose
      />
      <FormDialog
        {...editManifestFormDialogProps}
        disableProceed={isFormInvalid}
        loadingAction={isFormSubmitting}
        preActionArea={messageArea}
        ref={editManifestFormDialogRef}
        scrollContent
        showClose
      />
      <DialogWithHeader
        header={`${manifestDetail?.anvil ? 'Rerun' : 'Run'} install manifest ${
          manifestDetail?.name
        }`}
        loading={loadingRunForm}
        ref={runDialogRef}
        showClose
        wide
      >
        {runForm}
      </DialogWithHeader>
      <ConfirmDialog
        closeOnProceed
        {...oldConfirmDialogProps}
        ref={confirmDialogRef}
        scrollContent
        wide
      />
      {confirmDialog}
    </>
  );
};

export default ManageManifestPanel;
