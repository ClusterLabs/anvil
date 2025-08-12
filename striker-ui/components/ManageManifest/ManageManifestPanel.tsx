import { useMemo, useRef, useState } from 'react';

import { DialogWithHeader } from '../Dialog';
import FlexBox from '../FlexBox';
import FormScrollBox from '../Form/FormScrollBox';
import handleFormSubmit from '../Form/handleFormSubmit';
import IconButton from '../IconButton';
import List from '../List';
import ManifestForm from './ManifestForm';
import ManifestInputContext from './ManifestInputContext';
import ManifestInputGroup from './ManifestInputGroup';
import { Panel, PanelHeader } from '../Panels';
import RunManifestForm from './RunManifestForm';
import { BodyText, HeaderText } from '../Text';
import countHostFences from './countHostFences';
import getManifestFormikInitialValues from './getManifestFormikInitialValues';
import getManifestRequestBody from './getManifestRequestBody';
import useActiveFetch from '../../hooks/useActiveFetch';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';
import useFormUtils from '../../hooks/useFormUtils';
import buildManifestSchema from './schemas/buildManifestSchema';

const summaryMaxDepth = 6;

const ManageManifestPanel: React.FC = () => {
  const addDialogRef = useRef<DialogForwardedRefContent>(null);
  const editDialogRef = useRef<DialogForwardedRefContent>(null);
  const runDialogRef = useRef<DialogForwardedRefContent>(null);

  const [editManifests, setEditManifests] = useState<boolean>(false);

  const [manifest, setManifest] = useState<APIManifestDetail | undefined>();

  const {
    data: manifests,
    loading: loadingManifests,
    mutate: getManifestOverviews,
  } = useFetch<APIManifestOverviewList>('/manifest', {
    refreshInterval: 60000,
  });

  const {
    data: manifestTemplate,
    loading: loadingManifestTemplate,
    mutate: getManifestTemplate,
  } = useFetch<APIManifestTemplate>('/manifest/template');

  const {
    data: hosts,
    loading: loadingHosts,
    mutate: getHostOverviews,
  } = useFetch<APIHostDetailList>('/host?detail=1&type=subnode');

  const { fetch: getManifest, loading: loadingManifest } =
    useActiveFetch<APIManifestDetail>({
      onData: (data) => setManifest(data),
      url: `/manifest`,
    });

  const deleteUtils = useFormUtils([]);

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasChecks,
    resetChecks,
    setCheck,
  } = useChecklist({
    list: manifests,
  });

  const confirm = useConfirmDialog({
    initial: {
      scrollContent: true,
      wide: true,
    },
  });

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = confirm;

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

  const loadingMinimum =
    loadingManifests || loadingManifestTemplate || loadingHosts;

  const loadingAll = loadingMinimum || loadingManifest;

  const runForm = useMemo<React.ReactNode>(
    () =>
      manifestTemplate &&
      hosts &&
      manifest && (
        <RunManifestForm
          detail={manifest}
          knownFences={manifestTemplate.fences}
          knownHosts={hosts}
          knownUpses={manifestTemplate.upses}
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
      hosts,
      manifest,
      manifestTemplate,
    ],
  );

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Manage manifests</HeaderText>
        </PanelHeader>
        <List
          allowEdit
          allowItemButton={editManifests}
          disableDelete={!hasChecks}
          edit={editManifests}
          header
          listEmpty="No manifest(s) registered."
          listItems={manifests}
          loading={loadingMinimum}
          onAdd={() => {
            addDialogRef.current?.setOpen(true);
          }}
          onDelete={() => {
            confirm.setConfirmDialogProps(
              buildDeleteDialogProps({
                getConfirmDialogTitle: (count) =>
                  `Delete ${count} manifest(s)?`,
                onProceedAppend: () => {
                  deleteUtils.submitForm({
                    body: { uuids: checks },
                    getErrorMsg: (parentMsg) => {
                      confirm.finishConfirm('Error', {
                        children: `Delete manifest(s) failed. ${parentMsg}`,
                      });

                      return null;
                    },
                    method: 'delete',
                    onSuccess: () => {
                      resetChecks();

                      getManifestTemplate();
                      getManifestOverviews();

                      confirm.setConfirmDialogOpen(false);
                    },
                    url: `/manifest`,
                  });
                },
                renderEntry: ({ key }) => (
                  <BodyText>{manifests?.[key].manifestName}</BodyText>
                ),
              }),
            );

            confirm.setConfirmDialogOpen(true);
          }}
          onEdit={() => {
            setEditManifests((previous) => !previous);
          }}
          onItemCheckboxChange={(key, event, checked) => {
            setCheck(key, checked);
          }}
          onItemClick={({ manifestUUID }) => {
            editDialogRef.current?.setOpen(true);

            getManifest(`/${manifestUUID}`);
          }}
          renderListItemCheckboxState={(key) => getCheck(key)}
          renderListItem={(manifestUUID, { manifestName }) => (
            <FlexBox fullWidth row>
              <IconButton
                disabled={editManifests}
                mapPreset="play"
                onClick={() => {
                  runDialogRef.current?.setOpen(true);

                  getManifest(`/${manifestUUID}`);
                }}
                variant="normal"
              />
              <BodyText>{manifestName}</BodyText>
            </FlexBox>
          )}
        />
      </Panel>
      <DialogWithHeader
        header="Add an install manifest"
        loading={loadingMinimum}
        ref={addDialogRef}
        showClose
        wide
      >
        {manifests && manifestTemplate && hosts && (
          <ManifestForm
            config={{
              initialValues: getManifestFormikInitialValues(
                manifestTemplate,
                hosts,
              ),
              onSubmit: (values, helpers) => {
                const requestBody = getManifestRequestBody(
                  manifestTemplate,
                  values,
                );

                handleFormSubmit({
                  confirm,
                  getRequestBody: (ignore, summary) => summary,
                  getSummary: () => requestBody,
                  header: `Add install manifest with the following?`,
                  helpers,
                  onError: () => `Failed to add install manifest.`,
                  onSuccess: () => {
                    getManifestTemplate();
                    getManifestOverviews();

                    addDialogRef.current?.setOpen(false);

                    return `Successfully added install manifest`;
                  },
                  operation: 'add',
                  slotProps: {
                    confirm: {
                      preActionArea: (
                        <FlexBox spacing=".3em">
                          {countHostFences(requestBody).messages}
                        </FlexBox>
                      ),
                    },
                    summary: {
                      maxDepth: summaryMaxDepth,
                    },
                  },
                  url: '/manifest',
                  values,
                });
              },
              validationSchema: buildManifestSchema(manifests),
            }}
            operation="add"
          >
            <ManifestInputContext
              value={{
                hosts,
                template: manifestTemplate,
              }}
            >
              <FormScrollBox>
                <ManifestInputGroup />
              </FormScrollBox>
            </ManifestInputContext>
          </ManifestForm>
        )}
      </DialogWithHeader>
      <DialogWithHeader
        header={`Update install manifest ${manifest?.name}`}
        loading={loadingAll}
        ref={editDialogRef}
        showClose
        wide
      >
        {manifests && manifestTemplate && hosts && manifest && (
          <ManifestForm
            config={{
              initialValues: getManifestFormikInitialValues(
                manifestTemplate,
                hosts,
                manifest,
              ),
              onSubmit: (values, helpers) => {
                const requestBody = getManifestRequestBody(
                  manifestTemplate,
                  values,
                );

                handleFormSubmit({
                  confirm,
                  getRequestBody: (ignore, summary) => summary,
                  getSummary: () => requestBody,
                  header: `Update install manifest ${manifest.name} with the following?`,
                  helpers,
                  onError: () => `Failed to update install manifest.`,
                  onSuccess: () => {
                    getManifestTemplate();
                    getManifestOverviews();

                    editDialogRef.current?.setOpen(false);

                    return `Successfully updated install manifest ${manifest.name}`;
                  },
                  operation: 'edit',
                  slotProps: {
                    confirm: {
                      preActionArea: (
                        <FlexBox spacing=".3em">
                          {countHostFences(requestBody).messages}
                        </FlexBox>
                      ),
                    },
                    summary: {
                      maxDepth: summaryMaxDepth,
                    },
                  },
                  url: `/manifest/${manifest.uuid}`,
                  values,
                });
              },
              validationSchema: buildManifestSchema(manifests, manifest.name),
            }}
            operation="edit"
          >
            <ManifestInputContext
              value={{
                hosts,
                template: manifestTemplate,
              }}
            >
              <FormScrollBox>
                <ManifestInputGroup />
              </FormScrollBox>
            </ManifestInputContext>
          </ManifestForm>
        )}
      </DialogWithHeader>
      <DialogWithHeader
        header={`${manifest?.anvil ? 'Rerun' : 'Run'} install manifest ${
          manifest?.name
        }`}
        loading={loadingAll}
        ref={runDialogRef}
        showClose
        wide
      >
        {runForm}
      </DialogWithHeader>
      {confirmDialog}
    </>
  );
};

export default ManageManifestPanel;
