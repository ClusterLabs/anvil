import { FormikConfig, FormikValues, useFormik } from 'formik';
import { isEqual, isObject } from 'lodash';
import { useCallback, useMemo, useState } from 'react';

import debounce from '../lib/debounce';
import getFormikErrorMessages from '../lib/getFormikErrorMessages';

const isChainEqual = (
  chain: string[],
  current: Tree<unknown>,
  initial: Tree<unknown>,
): boolean => {
  const [part, ...remain] = chain;

  if (!(part in current)) {
    return false;
  }

  const a = current[part];
  const b = initial[part];

  if (isObject(a) && isObject(b) && remain.length) {
    return isChainEqual(remain, a as Tree<unknown>, b as Tree<unknown>);
  }

  return !isEqual(a, b);
};

const useFormikUtils = <Values extends FormikValues = FormikValues>(
  formikConfig: FormikConfig<Values>,
): FormikUtils<Values> => {
  const [changing, setChanging] = useState<boolean>(false);

  const formik = useFormik<Values>({ ...formikConfig });

  const getFieldChanged = useCallback(
    (field: string) => {
      const parts = field.split('.');

      return isChainEqual(parts, formik.values, formik.initialValues);
    },
    [formik.initialValues, formik.values],
  );

  const debounceHandleChange = useMemo(() => {
    const base = debounce((...args: Parameters<typeof formik.handleChange>) => {
      formik.handleChange(...args);
      setChanging(false);
    });

    return (...args: Parameters<typeof base>) => {
      setChanging(true);
      base(...args);
    };

    // Only handle change is being used in the debounced function, no need to
    // add the whole formik object as dependency.
    //
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [formik.handleChange]);

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
    handleChange: debounceHandleChange,
  };
};

export default useFormikUtils;
