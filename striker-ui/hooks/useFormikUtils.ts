import { FormikValues, getIn, setIn, useFormik } from 'formik';
import isEqual from 'lodash/isEqual';
import isObject from 'lodash/isObject';
import isString from 'lodash/isString';
import { useCallback, useMemo, useRef, useState } from 'react';
import * as yup from 'yup';

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
  const changed = useRef<Tree<boolean>>({});

  const getFieldChanged = useCallback(
    (field: string): boolean => getIn(changed.current, field),
    [],
  );

  const setFieldChanged = useCallback(
    (field: string, value: boolean = false): void => {
      changed.current = setIn(changed.current, field, value);
    },
    [],
  );

  const [changing, setChanging] = useState<boolean>(false);

  const formik = useFormik<Values>({ ...formikConfig });

  const changeFieldValue = useCallback<typeof formik.setFieldValue>(
    async (...args) => {
      const [field] = args;

      setFieldChanged(field, true);

      await formik.setFieldValue(...args);
    },

    // Only the field value setter is being used here
    //
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [formik.setFieldValue, setFieldChanged],
  );

  const getFieldIsDiff = useCallback(
    (field: string): boolean =>
      isEqualIn(formik.values, field, formik.initialValues),
    [formik.initialValues, formik.values],
  );

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

        setFieldChanged(target.name, true);
      }

      base(...args);
    };

    // Only handle change is being used in the debounced function, no need to
    // add the whole formik object as dependency.
    //
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [formik.handleChange, setFieldChanged]);

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

  const validationSchemaHelpers = useMemo<
    FormikValidationSchemaHelpers | undefined
  >(() => {
    if (!yup.isSchema(formikConfig.validationSchema)) {
      return undefined;
    }

    const description = formikConfig.validationSchema.describe();

    return {
      description,
      required: (field: string) => {
        if (!('fields' in description)) {
          return undefined;
        }

        const fieldDescription = description.fields[field];

        if (!fieldDescription || !('optional' in fieldDescription)) {
          return undefined;
        }

        return !fieldDescription.optional;
      },
    };
  }, [formikConfig.validationSchema]);

  return {
    changeFieldValue,
    disabledSubmit,
    formik,
    formikErrors,
    getFieldChanged,
    getFieldIsDiff,
    handleChange: debounceHandleChange,
    setFieldChanged,
    validationSchemaHelpers,
  };
};

export default useFormikUtils;
