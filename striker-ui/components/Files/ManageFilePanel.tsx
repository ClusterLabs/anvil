import { dSizeStr } from 'format-data-size';
import { FC, useCallback, useMemo, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';
import { UPLOAD_FILE_TYPES } from '../../lib/consts/UPLOAD_FILE_TYPES';

import AddFileForm from './AddFileForm';
import api from '../../lib/api';
import { toAnvilOverviewList } from '../../lib/api_converters';
import ConfirmDialog from '../ConfirmDialog';
import { DialogWithHeader } from '../Dialog';
import Divider from '../Divider';
import EditFileForm from './EditFileForm';
import FlexBox from '../FlexBox';
import List from '../List';
import MessageGroup, { MessageGroupForwardedRefContent } from '../MessageGroup';
import { Panel, PanelHeader } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import Spinner from '../Spinner';
import { BodyText, HeaderText, MonoText } from '../Text';
import useActiveFetch from '../../hooks/useActiveFetch';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialogProps from '../../hooks/useConfirmDialogProps';
import useFetch from '../../hooks/useFetch';

const toFileOverviewList = (rows: string[][]) =>
  rows.reduce<APIFileOverviewList>((previous, row) => {
    const [uuid, name, size, type, checksum] = row;

    previous[uuid] = {
      checksum,
      name,
      size,
      type: type as FileType,
      uuid,
    };

    return previous;
  }, {});

const toFileDetail = (rows: string[][]) => {
  const { 0: first } = rows;

  if (!first) return undefined;

  const [uuid, name, size, type, checksum] = first;

  return rows.reduce<APIFileDetail>(
    (previous, row) => {
      const {
        5: locationUuid,
        6: locationActive,
        7: anvilUuid,
        8: anvilName,
        9: anvilDescription,
        10: hostUuid,
        11: hostName,
        12: hostType,
      } = row;

      if (!previous.anvils[anvilUuid]) {
        previous.anvils[anvilUuid] = {
          description: anvilDescription,
          locationUuids: [],
          name: anvilName,
          uuid: anvilUuid,
        };
      }

      if (!previous.hosts[hostUuid]) {
        previous.hosts[hostUuid] = {
          locationUuids: [],
          name: hostName,
          type: hostType,
          uuid: hostUuid,
        };
      }

      if (hostType === 'dr') {
        previous.hosts[hostUuid].locationUuids.push(locationUuid);
      } else {
        previous.anvils[anvilUuid].locationUuids.push(locationUuid);
      }

      const active = Number(locationActive) === 1;

      previous.locations[locationUuid] = {
        anvilUuid,
        active,
        hostUuid,
        uuid: locationUuid,
      };

      return previous;
    },
    {
      anvils: {},
      checksum,
      hosts: {},
      locations: {},
      name,
      size,
      type: type as FileType,
      uuid,
    },
  );
};

const ManageFilePanel: FC = () => {
  const addFormDialogRef = useRef<DialogForwardedRefContent>(null);
  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent>({});
  const editFormDialogRef = useRef<DialogForwardedRefContent>(null);
  const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

  const [confirmDialogProps, setConfirmDialogProps] = useConfirmDialogProps();
  const [edit, setEdit] = useState<boolean>(false);
  const [file, setFile] = useState<APIFileDetail | undefined>();
  const [files, setFiles] = useState<APIFileOverviewList | undefined>();

  const { isLoading: loadingFilesPeriodic } = periodicFetch<string[][]>(
    `${API_BASE_URL}/file`,
    {
      onSuccess: (rows) => {
        setFiles(toFileOverviewList(rows));
      },
    },
  );

  const { fetch: getFiles, loading: loadingFilesActive } = useActiveFetch<
    string[][]
  >({
    onData: (data) => setFiles(toFileOverviewList(data)),
    url: '/file',
  });

  const loadingFiles = useMemo<boolean>(
    () => loadingFilesPeriodic || loadingFilesActive,
    [loadingFilesActive, loadingFilesPeriodic],
  );

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

  const { fetch: getFile, loading: loadingFile } = useActiveFetch<string[][]>({
    onData: (data) => setFile(toFileDetail(data)),
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
        renderListItem={(uuid, { checksum, name, size, type }) => (
          <FlexBox columnSpacing={0} fullWidth md="row" xs="column">
            <FlexBox spacing={0} flexGrow={1}>
              <FlexBox row spacing=".5em">
                <MonoText>{name}</MonoText>
                <Divider flexItem orientation="vertical" />
                <BodyText>{UPLOAD_FILE_TYPES.get(type)?.[1]}</BodyText>
              </FlexBox>
              <BodyText>{dSizeStr(size, { toUnit: 'ibyte' })}</BodyText>
            </FlexBox>
            <MonoText>{checksum}</MonoText>
          </FlexBox>
        )}
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
    () => loadingFilesPeriodic || loadingAnvils || loadingDrHosts,
    [loadingAnvils, loadingDrHosts, loadingFilesPeriodic],
  );

  const loadingEditForm = useMemo<boolean>(
    () =>
      loadingFilesPeriodic || loadingAnvils || loadingDrHosts || loadingFile,
    [loadingAnvils, loadingDrHosts, loadingFile, loadingFilesPeriodic],
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
