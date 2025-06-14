import { useEffect, useMemo, useRef, useState } from 'react';

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
  ...[props]: Parameters<
    React.FC<CrudListProps<Overview, Detail, OverviewList>>
  >
): ReturnType<React.FC<CrudListProps<Overview, Detail, OverviewList>>> => {
  const {
    addHeader: rAddHeader,
    editHeader: rEditHeader,
    entriesUrl,
    formDialogProps,
    getAddLoading,
    getDeleteErrorMessage,
    getDeleteHeader,
    getDeletePromiseChain = (base, ...args) => base(...args),
    getDeleteSuccessMessage,
    getEditLoading = (previous?: boolean) => previous,
    listEmpty,
    listProps,
    onItemClick = (base, { args }) => base(...args),
    onValidateEntriesChange,
    refreshInterval = 5000,
    renderAddForm,
    renderDeleteItem,
    renderEditForm,
    renderListItem,
    // Dependents
    entryUrlPrefix = entriesUrl,
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

  const {
    data: entries,
    mutate: refreshEntries,
    loading: loadingEntries,
    validating: validatingEntries,
  } = useFetch<OverviewList>(entriesUrl, { refreshInterval });

  const { fetch: getEntry, loading: loadingEntry } = useActiveFetch<Detail>({
    onData: (data) => setEntry(data),
    url: entryUrlPrefix,
  });

  useEffect(() => {
    onValidateEntriesChange?.call(null, validatingEntries);
  }, [onValidateEntriesChange, validatingEntries]);

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
      add: {
        open: (v = true) => addDialogRef?.current?.setOpen(v),
      },
      confirm: {
        finish: finishConfirm,
        loading: setConfirmDialogLoading,
        open: (v = true) => setConfirmDialogOpen(v),
        prepare: setConfirmDialogProps,
      },
      edit: {
        open: (v = true) => editDialogRef?.current?.setOpen(v),
      },
    }),
    [
      finishConfirm,
      setConfirmDialogLoading,
      setConfirmDialogOpen,
      setConfirmDialogProps,
    ],
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

  const entryRef = useMemo<CrudListEntryRef<Detail>>(
    () => ({
      set: setEntry,
      value: entry,
    }),
    [entry],
  );

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
                  getDeletePromiseChain(
                    (cl, up) => cl.map((key) => api.delete(`${up}/${key}`)),
                    checks,
                    entriesUrl,
                  ),
                )
                  .then(() => {
                    finishConfirm('Success', getDeleteSuccessMessage());

                    refreshEntries();
                  })
                  .catch((error) => {
                    const emsg = handleAPIError(error);

                    finishConfirm('Error', getDeleteErrorMessage(emsg));
                  })
                  .finally(() => {
                    resetChecks();
                  });
              },
              getConfirmDialogTitle: getDeleteHeader,
              renderEntry: (...args) => renderDeleteItem(entries, ...args),
            }),
          );

          setConfirmDialogOpen(true);
        }}
        onEdit={() => setEdit((previous) => !previous)}
        onItemClick={(...args) =>
          onItemClick(
            (value, key) => {
              editDialogRef?.current?.setOpen(true);

              getEntry(`/${key}`);
            },
            {
              args,
              entry: entryRef,
              tools: formTools,
            },
          )
        }
        renderListItem={renderListItem}
        {...listProps}
      />
      <DialogWithHeader
        header={addHeader}
        loading={getAddLoading?.call(null)}
        ref={addDialogRef}
        showClose
        {...formDialogProps?.common}
        {...formDialogProps?.add}
      >
        {renderAddForm(formTools, entries)}
      </DialogWithHeader>
      <DialogWithHeader
        header={editHeader}
        loading={getEditLoading(loadingEntry)}
        ref={editDialogRef}
        showClose
        {...formDialogProps?.common}
        {...formDialogProps?.edit}
      >
        {renderEditForm(formTools, entry, entries)}
      </DialogWithHeader>
      {confirmDialog}
    </>
  );
};

export default CrudList;
