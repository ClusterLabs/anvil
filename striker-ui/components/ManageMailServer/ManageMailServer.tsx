import { FC, useRef, useState } from 'react';

import API_BASE_URL from '../../lib/consts/API_BASE_URL';

import AddMailServerForm from './AddMailServerForm';
import api from '../../lib/api';
import { DialogWithHeader } from '../Dialog';
import EditMailServerForm from './EditMailServerForm';
import FormSummary from '../FormSummary';
import List from '../List';
import { ExpandablePanel } from '../Panels';
import periodicFetch from '../../lib/fetchers/periodicFetch';
import { BodyText } from '../Text';
import useActiveFetch from '../../hooks/useActiveFetch';
import useChecklist from '../../hooks/useChecklist';
import useConfirmDialog from '../../hooks/useConfirmDialog';
import useFetch from '../../hooks/useFetch';

const ManageMailServer: FC = () => {
  const addDialogRef = useRef<DialogForwardedRefContent>(null);
  const editDialogRef = useRef<DialogForwardedRefContent>(null);

  const { confirmDialog, setConfirmDialogOpen, setConfirmDialogProps } =
    useConfirmDialog({ initial: { closeOnProceed: true } });

  const [edit, setEdit] = useState<boolean>(false);
  const [mailServer, setMailServer] = useState<
    APIMailServerDetail | undefined
  >();
  const [mailServers, setMailServers] = useState<
    APIMailServerOverviewList | undefined
  >();

  const { isLoading: loadingMailServersPeriodic } =
    periodicFetch<APIMailServerOverviewList>(`${API_BASE_URL}/mail-server`, {
      onSuccess: (data) => setMailServers(data),
    });

  const { fetch: getMailServers, loading: loadingMailServersActive } =
    useActiveFetch<APIMailServerOverviewList>({
      onData: (data) => setMailServers(data),
      url: '/mail-server',
    });

  const { fetch: getMailServer, loading: loadingMailServer } =
    useActiveFetch<APIMailServerDetail>({
      onData: (data) => setMailServer(data),
      url: '/mail-server',
    });

  const { data: host, loading: loadingHost } =
    useFetch<APIHostDetail>('/host/local');

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
  } = useChecklist({ list: mailServers });

  return (
    <>
      <ExpandablePanel expandInitially header="Manage mail servers">
        <List
          allowCheckAll={multipleItems}
          allowEdit
          allowItemButton={edit}
          disableDelete={!hasChecks}
          edit={edit}
          getListCheckboxProps={() => ({
            checked: hasAllChecks,
            onChange: (event, checked) => setAllChecks(checked),
          })}
          getListItemCheckboxProps={(uuid) => ({
            checked: getCheck(uuid),
            onChange: (event, checked) => setCheck(uuid, checked),
          })}
          header
          listEmpty="No mail server(s) found."
          listItems={mailServers}
          loading={loadingMailServersPeriodic || loadingMailServersActive}
          onAdd={() => addDialogRef?.current?.setOpen(true)}
          onDelete={() => {
            setConfirmDialogProps({
              ...buildDeleteDialogProps({
                onProceedAppend: () => {
                  Promise.all(
                    checks.map((uuid) => api.delete(`/mail-server/${uuid}`)),
                  ).then(() => getMailServers());

                  resetChecks();
                },
                getConfirmDialogTitle: (count) =>
                  `Delete the following ${count} mail server(s)?`,
                renderEntry: ({ key }) => {
                  const ms = mailServers?.[key];

                  return (
                    <BodyText>
                      {ms?.address}:{ms?.port}
                    </BodyText>
                  );
                },
              }),
            });

            setConfirmDialogOpen(true);
          }}
          onEdit={() => setEdit((previous) => !previous)}
          onItemClick={(value, uuid) => {
            editDialogRef?.current?.setOpen(true);

            getMailServer(`/${uuid}`);
          }}
          renderListItem={(uuid, { address, port }) => (
            <BodyText>
              {address}:{port}
            </BodyText>
          )}
        />
      </ExpandablePanel>
      <DialogWithHeader
        header="Add mail server"
        loading={loadingMailServersPeriodic || loadingHost}
        ref={addDialogRef}
        showClose
      >
        {host && (
          <AddMailServerForm
            localhostDomain={host.domain}
            onSubmit={(tools, ...args) => {
              setConfirmDialogProps({
                actionProceedText: 'Add',
                content: <FormSummary entries={tools.mailServer} />,
                onCancelAppend: () => tools.onConfirmCancel(...args),
                onProceedAppend: () => tools.onConfirmProceed(...args),
                titleText: 'Add mail server with the following?',
              });

              setConfirmDialogOpen(true);
            }}
          />
        )}
      </DialogWithHeader>
      <DialogWithHeader
        header="Update mail server"
        loading={loadingMailServersPeriodic || loadingMailServer}
        ref={editDialogRef}
        showClose
      >
        {mailServer && (
          <EditMailServerForm
            mailServerUuid={mailServer.uuid}
            onSubmit={(tools, ...args) => {
              setConfirmDialogProps({
                actionProceedText: 'Update',
                content: <FormSummary entries={tools.mailServer} />,
                onCancelAppend: () => tools.onConfirmCancel(...args),
                onProceedAppend: () => tools.onConfirmProceed(...args),
                titleText: 'Update mail server with the following?',
              });

              setConfirmDialogOpen(true);
            }}
            previousFormikValues={{ [mailServer.uuid]: mailServer }}
          />
        )}
      </DialogWithHeader>
      {confirmDialog}
    </>
  );
};

export default ManageMailServer;
