import MuiGrid from '@mui/material/Grid2';
import { createContext, useContext, useMemo } from 'react';

import FormActionGroup, { FormActionGroupProps } from './FormActionGroup';
import FormGrid, { FormGridProps } from './FormGrid';
import FormMessageGroup, { FormMessageGroupProps } from './FormMessageGroup';
import useFormikUtils from '../../hooks/useFormikUtils';

type FormContextValue<V extends FormikValues> = {
  formikUtils: FormikUtils<V>;
};

type FormFactoryParams<V extends FormikValues> = {
  context?: {
    defaultValue?: FormContextValue<V> | null;
  };
};

type FormProps<V extends FormikValues> = Pick<
  FormActionGroupProps<V>,
  'operation'
> & {
  config: FormikConfig<V>;
  slotProps?: {
    actions?: FormActionGroupProps<V>;
    grid?: FormGridProps<V>;
    messages?: FormMessageGroupProps<V>;
  };
};

const createForm = <V extends FormikValues>(params?: FormFactoryParams<V>) => {
  const FormContext: React.Context<FormContextValue<V> | null> =
    createContext<FormContextValue<V> | null>(
      params?.context?.defaultValue ?? null,
    );

  const Form: React.FC<React.PropsWithChildren<FormProps<V>>> = (props) => {
    const { children, config, operation, slotProps } = props;

    const formikUtils = useFormikUtils<V>(config);

    const formContextValue = useMemo<FormContextValue<V> | null>(
      () => ({
        formikUtils,
      }),
      [formikUtils],
    );

    return (
      <FormGrid formikUtils={formikUtils} {...slotProps?.grid}>
        <MuiGrid width="100%">
          <FormContext value={formContextValue}>{children}</FormContext>
        </MuiGrid>
        <MuiGrid width="100%">
          <FormMessageGroup
            formikUtils={formikUtils}
            {...slotProps?.messages}
          />
        </MuiGrid>
        <MuiGrid width="100%">
          <FormActionGroup
            formikUtils={formikUtils}
            operation={operation}
            {...slotProps?.actions}
          />
        </MuiGrid>
      </FormGrid>
    );
  };

  const useFormContext = useContext<FormContextValue<V> | null>;

  return {
    Form,
    FormContext,
    useFormContext,
  };
};

export type { FormContextValue, FormFactoryParams, FormProps };

export default createForm;
