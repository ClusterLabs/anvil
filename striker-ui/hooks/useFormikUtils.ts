import { OutlinedInputProps } from '@mui/material';
import { FormikValues, useFormik } from 'formik';
import { useCallback, useMemo } from 'react';

import debounce from '../lib/debounce';
import getFormikErrorMessages from '../lib/getFormikErrorMessages';

const useFormikUtils = <Values extends FormikValues = FormikValues>(
  ...formikArgs: Parameters<UseFormik<Values>>
): FormikUtils<Values> => {
  const [formikConfig, ...restFormikArgs] = formikArgs;

  const formik = useFormik<Values>({ ...formikConfig }, ...restFormikArgs);

  const getFieldChanged = useCallback(
    (field: string) => {
      const parts = field.split('.');

      const traverse = (values: Tree<unknown>): boolean =>
        parts.reduce<boolean>((previous, part) => {
          if (!(part in values)) {
            return false;
          }

          const value = values[part];

          if (value !== null && typeof value === 'object') {
            return traverse(value as Tree<unknown>);
          }

          return value === formik.initialValues[part];
        }, false);

      return traverse(formik.values);
    },
    [formik.initialValues, formik.values],
  );

  const disableAutocomplete = useCallback(
    (overwrite?: Partial<OutlinedInputProps>): OutlinedInputProps => ({
      readOnly: true,
      onFocus: (event) => {
        event.target.readOnly = false;
      },
      ...overwrite,
    }),
    [],
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
    disableAutocomplete,
    disabledSubmit,
    formik,
    formikErrors,
    handleChange: debounceHandleChange,
  };
};

export default useFormikUtils;
