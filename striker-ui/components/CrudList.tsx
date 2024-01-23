import { FC, useMemo, useRef, useState } from 'react';

import api from '../lib/api';
import { DialogWithHeader } from './Dialog';
import handleAPIError from '../lib/handleAPIError';
import List from './List';
import useActiveFetch from '../hooks/useActiveFetch';
import useChecklist from '../hooks/useChecklist';
import useConfirmDialog from '../hooks/useConfirmDialog';
import useFetch from '../hooks/useFetch';

const reduceHeader = <A extends unknown[], R extends React.ReactNode>(
  header: R | ((...args: A) => R),
  ...args: A
): R => (typeof header === 'function' ? header(...args) : header);

const CrudList = <
  Overview,
  Detail,
  OverviewList extends Record<string, Overview> = Record<string, Overview>,
>(
  ...[props]: Parameters<FC<CrudListProps<Overview, Detail, OverviewList>>>
): ReturnType<FC<CrudListProps<Overview, Detail, OverviewList>>> => {
  const {
    addHeader: rAddHeader,
    editHeader: rEditHeader,
    entriesUrl,
    getAddLoading,
    getDeleteErrorMessage,
    getDeleteHeader,
    getDeleteSuccessMessage,
    getEditLoading = (previous?: boolean) => previous,
    listEmpty,
    listProps,
    onItemClick = (base, ...args) => base(...args),
    refreshInterval = 5000,
    renderAddForm,
    renderDeleteItem,
    renderEditForm,
    renderListItem,
  } = props;

  const addDialogRef = useRef<DialogForwardedRefContent>(null);
  const editDialogRef = useRef<DialogForwardedRefContent>(null);

  const {
    confirmDialog,
    finishConfirm,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
  } = useConfirmDialog({ initial: { scrollContent: true } });

  const [edit, setEdit] = useState<boolean>(false);
  const [entry, setEntry] = useState<Detail | undefined>();
  const [entries, setEntries] = useState<OverviewList | undefined>();

  const { loading: loadingEntriesPeriodic } = useFetch<OverviewList>(
    entriesUrl,
    {
      onSuccess: (data) => setEntries(data),
      refreshInterval,
    },
  );

  const { fetch: getEntries, loading: loadingEntriesActive } =
    useActiveFetch<OverviewList>({
      onData: (data) => setEntries(data),
      url: entriesUrl,
    });

  const { fetch: getEntry, loading: loadingEntry } = useActiveFetch<Detail>({
    onData: (data) => setEntry(data),
    url: entriesUrl,
  });

  const addHeader = useMemo<React.ReactNode>(
    () => reduceHeader(rAddHeader),
    [rAddHeader],
  );

  const editHeader = useMemo<React.ReactNode>(
    () => reduceHeader(rEditHeader, entry),
    [entry, rEditHeader],
  );

  const formTools = useMemo<CrudListFormTools>(
    () => ({
      confirm: {
        finish: finishConfirm,
        loading: setConfirmDialogLoading,
        open: setConfirmDialogOpen,
        prepare: setConfirmDialogProps,
      },
    }),
    [
      finishConfirm,
      setConfirmDialogLoading,
      setConfirmDialogOpen,
      setConfirmDialogProps,
    ],
  );

  const loadingEntries = useMemo<boolean>(
    () => loadingEntriesPeriodic || loadingEntriesActive,
    [loadingEntriesActive, loadingEntriesPeriodic],
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
  } = useChecklist({ list: entries });

  return (
    <>
      <List<Overview>
        allowCheckAll={multipleItems}
        allowEdit
        allowItemButton={edit}
        disableDelete={!hasChecks}
        edit={edit}
        getListCheckboxProps={() => ({
          checked: hasAllChecks,
          onChange: (event, checked) => setAllChecks(checked),
        })}
        getListItemCheckboxProps={(key) => ({
          checked: getCheck(key),
          onChange: (event, checked) => setCheck(key, checked),
        })}
        header
        listEmpty={listEmpty}
        listItems={entries}
        loading={loadingEntries}
        onAdd={() => addDialogRef?.current?.setOpen(true)}
        onDelete={() => {
          setConfirmDialogProps(
            buildDeleteDialogProps({
              onProceedAppend: () => {
                setConfirmDialogLoading(true);

                Promise.all(
                  checks.map((key) => api.delete(`${entriesUrl}/${key}`)),
                )
                  .then(() => {
                    finishConfirm('Success', getDeleteSuccessMessage());

                    getEntries();
                  })
                  .catch((error) => {
                    const emsg = handleAPIError(error);

                    finishConfirm('Error', getDeleteErrorMessage(emsg));
                  });

                resetChecks();
              },
              getConfirmDialogTitle: getDeleteHeader,
              renderEntry: (...args) => renderDeleteItem(entries, ...args),
            }),
          );

          setConfirmDialogOpen(true);
        }}
        onEdit={() => setEdit((previous) => !previous)}
        onItemClick={(...args) =>
          onItemClick((value, key) => {
            editDialogRef?.current?.setOpen(true);

            getEntry(`/${key}`);
          }, ...args)
        }
        renderListItem={renderListItem}
        {...listProps}
      />
      <DialogWithHeader
        header={addHeader}
        loading={getAddLoading?.call(null)}
        ref={addDialogRef}
        showClose
      >
        {renderAddForm(formTools)}
      </DialogWithHeader>
      <DialogWithHeader
        header={editHeader}
        loading={getEditLoading(loadingEntry)}
        ref={editDialogRef}
        showClose
      >
        {renderEditForm(formTools, entry)}
      </DialogWithHeader>
      {confirmDialog}
    </>
  );
};

export default CrudList;
