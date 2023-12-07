import { useCallback, useMemo, useState } from 'react';

import buildObjectStateSetterCallback from '../lib/buildObjectStateSetterCallback';

import FormSummary from '../components/FormSummary';

const useChecklist = ({
  list = {},
}: {
  list?: Record<string, unknown>;
}): {
  buildDeleteDialogProps: BuildDeleteDialogPropsFunction;
  checklist: Checklist;
  checks: ArrayChecklist;
  getCheck: GetCheckFunction;
  hasAllChecks: boolean;
  hasChecks: boolean;
  multipleItems: boolean;
  resetChecks: () => void;
  setAllChecks: SetAllChecksFunction;
  setCheck: SetCheckFunction;
} => {
  const [checklist, setChecklist] = useState<Checklist>({});

  const listKeys = useMemo(() => Object.keys(list), [list]);
  const checks = useMemo(() => Object.keys(checklist), [checklist]);

  const hasAllChecks = useMemo(
    () => checks.length === listKeys.length,
    [checks.length, listKeys.length],
  );
  const hasChecks = useMemo(() => checks.length > 0, [checks.length]);
  const multipleItems = useMemo(() => listKeys.length > 1, [listKeys.length]);

  const buildDeleteDialogProps = useCallback<BuildDeleteDialogPropsFunction>(
    ({
      confirmDialogProps = {},
      formSummaryProps = {},
      getConfirmDialogTitle,
      onProceedAppend,
      renderEntry,
    }) => ({
      actionProceedText: 'Delete',
      content: (
        <FormSummary
          entries={checklist}
          maxDepth={0}
          renderEntry={renderEntry}
          {...formSummaryProps}
        />
      ),
      onProceedAppend,
      proceedColour: 'red',
      titleText: getConfirmDialogTitle(checks.length),
      ...confirmDialogProps,
    }),
    [checklist, checks.length],
  );

  const getCheck = useCallback<GetCheckFunction>(
    (key) => checklist[key],
    [checklist],
  );

  const resetChecks = useCallback(() => setChecklist({}), []);

  const setAllChecks = useCallback<SetAllChecksFunction>(
    (checked) =>
      setChecklist(
        listKeys.reduce<Checklist>((previous, key) => {
          if (checked) {
            previous[key] = checked;
          }

          return previous;
        }, {}),
      ),
    [listKeys],
  );

  const setCheck = useCallback<SetCheckFunction>(
    (key, checked) =>
      setChecklist(buildObjectStateSetterCallback(key, checked || undefined)),
    [],
  );

  return {
    buildDeleteDialogProps,
    checklist,
    checks,
    getCheck,
    hasAllChecks,
    hasChecks,
    multipleItems,
    resetChecks,
    setAllChecks,
    setCheck,
  };
};

export default useChecklist;
