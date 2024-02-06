import { FormikConfig, FormikValues, useFormik } from 'formik';
import { isEqual, isObject } from 'lodash';
import { useCallback, useMemo } from 'react';

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
  const formik = useFormik<Values>({ ...formikConfig });

  const getFieldChanged = useCallback(
    (field: string) => {
      const parts = field.split('.');

      return isChainEqual(parts, formik.values, formik.initialValues);
    },
    [formik.initialValues, formik.values],
  );

  const debounceHandleChange = useMemo(
    () => debounce(formik.handleChange),
    [formik.handleChange],
  );

  const disabledSubmit = useMemo(
    () =>
      !formik.dirty ||
      !formik.isValid ||
      formik.isValidating ||
      formik.isSubmitting,
    [formik.dirty, formik.isSubmitting, formik.isValid, formik.isValidating],
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
