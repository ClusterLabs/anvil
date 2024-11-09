import { Grid } from '@mui/material';
import { dSizeStr } from 'format-data-size';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import AddFileForm from './AddFileForm';
import api from '../../lib/api';
import { toAnvilOverviewList } from '../../lib/api_converters';
import CircularProgress from '../CircularProgress';
import ConfirmDialog from '../ConfirmDialog';
import { DialogWithHeader } from '../Dialog';
import Divider from '../Divider';
import EditFileForm from './EditFileForm';
import FlexBox from '../FlexBox';
import List from '../List';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import Spinner from '../Spinner';
import { BodyText, HeaderText, MonoText } from '../Text';
import useActiveFetch from '../../hooks/useActiveFetch';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFetch from '../../hooks/useFetch';

const ManageFilePanel: FC = () => {
  const addFormDialogRef = useRef<DialogForwardedRefContent>(null);
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editFormDialogRef = useRef<DialogForwardedRefContent>(null);
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();
  const [edit, setEdit] = useState<boolean>(false);
  const [file, setFile] = useState<APIFileDetail | undefined>();

  const {
    data: files,
    loading: loadingFiles,
    mutate: getFiles,
  } = useFetch<APIFileOverviewList>('/file', {
    refreshInterval: 5000,
  });

  const {
    buildDeleteDialogProps,
    checks,
    getCheck,
    hasAllChecks,
    hasChecks,
    multipleItems,
    resetChecks,
    setAllChecks,
    setCheck,
  } = useChecklist({
    list: files,
  });

  const setApiMessage = useCallback(
    (message: Message) =>
      messageGroupRef.current.setMessage?.call(null, 'api', message),
    [],
  );

  const { fetch: getFile, loading: loadingFile } =
    useActiveFetch<APIFileDetail>({
      onData: (data) => setFile(data),
      onError: ({ children: previous, ...rest }) => {
        setApiMessage({
          children: <>Failed to get file detail. {previous}</>,
          ...rest,
        });
      },
      url: '/file/',
    });

  const { data: rawAnvils, loading: loadingAnvils } =
    useFetch<APIAnvilOverviewArray>('/anvil', {
      onError: (error) => {
        setApiMessage({
          children: <>Failed to get node list. {error}</>,
          type: 'warning',
        });
      },
    });

  const anvils = useMemo(
    () => rawAnvils && toAnvilOverviewList(rawAnvils),
    [rawAnvils],
  );

  const { data: drHosts, loading: loadingDrHosts } =
    useFetch<APIHostOverviewList>('/host?types=dr', {
      onError: (error) => {
        setApiMessage({
          children: <>Failed to get DR host list. {error}</>,
          type: 'warning',
        });
      },
    });

  const list = useMemo(
    () => (
      <List
        allowCheckAll={multipleItems}
        allowEdit
        allowItemButton={edit}
        disableDelete={!hasChecks}
        edit={edit}
        getListCheckboxProps={() => ({
          checked: hasAllChecks,
          onChange: (event, checked) => {
            setAllChecks(checked);
          },
        })}
        getListItemCheckboxProps={(uuid) => ({
          checked: getCheck(uuid),
          onChange: (event, checked) => {
            setCheck(uuid, checked);
          },
        })}
        header
        listEmpty="No file(s) found."
        listItems={files}
        onAdd={() => {
          addFormDialogRef.current?.setOpen(true);
        }}
        onDelete={() => {
          setConfirmDialogProps(
            buildDeleteDialogProps({
              onProceedAppend: () => {
                const promises = checks.map((fileUuid) =>
                  api.delete(`/file/${fileUuid}`),
                );

                Promise.all(promises).then(() => getFiles());

                resetChecks();
              },
              getConfirmDialogTitle: (count) =>
                `Delete the following ${count} file(s)?`,
              renderEntry: ({ key }) => (
                <BodyText>{files?.[key].name}</BodyText>
              ),
            }),
          );

          confirmDialogRef.current.setOpen?.call(null, true);
        }}
        onEdit={() => {
          setEdit((previous) => !previous);
        }}
        onItemClick={(value, uuid) => {
          editFormDialogRef.current?.setOpen(true);
          getFile(uuid);
        }}
        renderListItem={(
          uuid,
          { anvils: locations, checksum, name, size, type },
        ) => {
          const syncing = Object.values(locations).some(({ ready }) => !ready);

          return (
            <Grid container columnGap="1em">
              {syncing && (
                <Grid alignSelf="center" item>
                  <CircularProgress size="1.5em" variant="indeterminate" />
                </Grid>
              )}
              <Grid item xs>
                <FlexBox
                  columnSpacing={0}
                  rowSpacing=".5em"
                  sm="row"
                  xs="column"
                >
                  <MonoText noWrap>{name}</MonoText>
                  <Divider flexItem orientation="vertical" />
                  <BodyText>{UPLOAD_FILE_TYPES.get(type)?.[1]}</BodyText>
                </FlexBox>
                <FlexBox row spacing=".5em">
                  {syncing && <BodyText>Syncing...</BodyText>}
                  <BodyText>{dSizeStr(size, { toUnit: 'ibyte' })}</BodyText>
                </FlexBox>
              </Grid>
              <Grid alignSelf="center" item width={{ xs: '100%', md: 'auto' }}>
                <MonoText noWrap>{checksum}</MonoText>
              </Grid>
            </Grid>
          );
        }}
      />
    ),
    [
      buildDeleteDialogProps,
      checks,
      edit,
      files,
      getCheck,
      getFile,
      getFiles,
      hasAllChecks,
      hasChecks,
      multipleItems,
      resetChecks,
      setAllChecks,
      setCheck,
      setConfirmDialogProps,
    ],
  );

  const panelContent = useMemo(
    () => (loadingFiles ? <Spinner /> : list),
    [loadingFiles, list],
  );

  const messageArea = useMemo(
    () => (
      <MessageGroup count={1} ref={messageGroupRef} usePlaceholder={false} />
    ),
    [],
  );

  const loadingAddForm = useMemo<boolean>(
    () => loadingFiles || loadingAnvils || loadingDrHosts,
    [loadingAnvils, loadingDrHosts, loadingFiles],
  );

  const loadingEditForm = useMemo<boolean>(
    () => loadingFiles || loadingAnvils || loadingDrHosts || loadingFile,
    [loadingAnvils, loadingDrHosts, loadingFile, loadingFiles],
  );

  const addForm = useMemo(
    () =>
      anvils && drHosts && <AddFileForm anvils={anvils} drHosts={drHosts} />,
    [anvils, drHosts],
  );

  const editForm = useMemo(
    () =>
      anvils &&
      drHosts &&
      file && (
        <EditFileForm
          anvils={anvils}
          drHosts={drHosts}
          onSuccess={() => {
            getFiles();
          }}
          previous={file}
        />
      ),
    [anvils, drHosts, file, getFiles],
  );

  return (
    <>
      <Panel>
        <PanelHeader>
          <HeaderText>Files</HeaderText>
        </PanelHeader>
        {messageArea}
        {panelContent}
      </Panel>
      <DialogWithHeader
        header="Add file(s)"
        loading={loadingAddForm}
        ref={addFormDialogRef}
        showClose
        wide
      >
        {addForm}
      </DialogWithHeader>
      <DialogWithHeader
        header={`Update file ${file?.name}`}
        loading={loadingEditForm}
        ref={editFormDialogRef}
        showClose
        wide
      >
        {editForm}
      </DialogWithHeader>
      <ConfirmDialog
        closeOnProceed
        wide
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    </>
  );
};

export default ManageFilePanel;
