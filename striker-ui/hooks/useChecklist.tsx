import { useCallback, useMemo, useState } from 'react';

import buildObjectStateSetterCallback from '../lib/buildObjectStateSetterCallback';

import FormSummary from '../components/FormSummary';

const useChecklist = (): {
  buildDeleteDialogProps: BuildDeleteDialogPropsFunction;
  checklist: Checklist;
  checks: ArrayChecklist;
  getCheck: GetCheckFunction;
  hasChecks: boolean;
  setCheck: SetCheckFunction;
} => {
  const [checklist, setChecklist] = useState<Checklist>({});

  const checks = useMemo(() => Object.keys(checklist), [checklist]);

  const hasChecks = useMemo(() => checks.length > 0, [checks.length]);

  const buildDeleteDialogProps = useCallback<BuildDeleteDialogPropsFunction>(
    ({
      confirmDialogProps = {},
      formSummaryProps = {},
      getConfirmDialogTitle,
    }) => ({
      actionProceedText: 'Delete',
      content: (
        <FormSummary entries={checklist} maxDepth={0} {...formSummaryProps} />
      ),
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
    hasChecks,
    setCheck,
  };
};

export default useChecklist;
