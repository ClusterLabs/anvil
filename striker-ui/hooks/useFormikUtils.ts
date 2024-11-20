import { FormikConfig, FormikValues, getIn, setIn, useFormik } from 'formik';
import { isEqual, isObject, isString } from 'lodash';
import { useCallback, useMemo, useState } from 'react';

import debounce from '../lib/debounce';
import getFormikErrorMessages from '../lib/getFormikErrorMessages';

const isEqualIn = (
  source: Tree<unknown>,
  path: string | string[],
  target: Tree<unknown>,
): boolean => {
  const chain = isString(path) ? path.split('.') : path;
  const [part, ...remain] = chain;

  if (!(part in source)) {
    return false;
  }

  const a = source[part];
  const b = target[part];

  if (isObject(a) && isObject(b) && remain.length) {
    return isEqualIn(a as Tree<unknown>, remain, b as Tree<unknown>);
  }

  return !isEqual(a, b);
};

const useFormikUtils = <Values extends FormikValues = FormikValues>(
  formikConfig: FormikConfig<Values>,
): FormikUtils<Values> => {
  const [changed, setChanged] = useState<Tree<boolean>>({});
  const [changing, setChanging] = useState<boolean>(false);

  const formik = useFormik<Values>({ ...formikConfig });

  const debounceHandleChange = useMemo(() => {
    const base = debounce((...args: Parameters<typeof formik.handleChange>) => {
      formik.handleChange(...args);
      setChanging(false);
    });

    return (...args: Parameters<typeof formik.handleChange>) => {
      setChanging(true);

      const [maybeEvent] = args;

      if (!isString(maybeEvent)) {
        const event = maybeEvent as React.ChangeEvent<{ name: string }>;
        const target = event.target ? event.target : event.currentTarget;

        setChanged((prev) => setIn(prev, target.name, true));
      }

      base(...args);
    };

    // Only handle change is being used in the debounced function, no need to
    // add the whole formik object as dependency.
    //
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [formik.handleChange]);

  const getFieldChanged = useCallback(
    (field: string): boolean => getIn(changed, field),
    [changed],
  );

  const getFieldIsDiff = useCallback(
    (field: string): boolean =>
      isEqualIn(formik.values, field, formik.initialValues),
    [formik.initialValues, formik.values],
  );

  const setFieldChanged = useCallback(
    (field: string, value: boolean = false): void => {
      setChanged((prev) => setIn(prev, field, value));
    },
    [],
  );

  const disabledSubmit = useMemo(
    () =>
      changing ||
      !formik.dirty ||
      !formik.isValid ||
      formik.isValidating ||
      formik.isSubmitting,
    [
      changing,
      formik.dirty,
      formik.isSubmitting,
      formik.isValid,
      formik.isValidating,
    ],
  );

  const formikErrors = useMemo<Messages>(
    () =>
      getFormikErrorMessages(formik.errors, {
        skip: (field) => !getFieldChanged(field),
      }),
    [formik.errors, getFieldChanged],
  );

  return {
    disabledSubmit,
    formik,
    formikErrors,
    getFieldChanged,
    getFieldIsDiff,
    handleChange: debounceHandleChange,
    setFieldChanged,
  };
};

export default useFormikUtils;
