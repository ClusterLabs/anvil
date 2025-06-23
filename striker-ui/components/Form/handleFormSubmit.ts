import { AxiosError, Method } from 'axios';
import { FormikHelpers } from 'formik';
import { createElement, Fragment } from 'react';

import { FormOperation } from './FormActionGroup';
import FormSummary from '../FormSummary';
import api from '../../lib/api';
import handleAPIError from '../../lib/handleAPIError';

type FormSubmitHandlerParams<
  V extends FormikValues,
  S extends Record<string, unknown> = Record<string, unknown>,
  ReqBody = unknown,
  ResBody = unknown,
> = {
  confirm?: ConfirmDialogUtils;
  description?: React.ReactNode;
  getRequestBody?: (values: V, summary?: S) => ReqBody;
  getSummary?: (values: V) => S;
  header: React.ReactNode;
  helpers: FormikHelpers<V>;
  method?: Method;
  onError?: (error: AxiosError<ReqBody, ResBody>) => React.ReactNode;
  onSuccess?: () => React.ReactNode;
  operation: FormOperation;
  tools?: CrudListFormTools;
  url: string;
  values: V;
};

const toConfirmHelpers = (
  utils: ConfirmDialogUtils,
): CrudListConfirmHelpers => ({
  finish: utils.finishConfirm,
  loading: utils.setConfirmDialogLoading,
  open: (value = false) => utils.setConfirmDialogOpen(value),
  prepare: utils.setConfirmDialogProps,
});

const toMethod = (operation: FormOperation): Method => {
  switch (operation) {
    case 'add':
      return 'post';
    case 'delete':
      return 'delete';
    default:
      return 'put';
  }
};

const toProceedLabel = (operation: FormOperation): string => {
  switch (operation) {
    case 'add':
      return 'Add';
    case 'delete':
      return 'Delete';
    default:
      return 'Save';
  }
};

const handleFormSubmit = <V extends FormikValues>(
  params: FormSubmitHandlerParams<V>,
) => {
  const {
    description,
    getRequestBody,
    getSummary,
    header,
    helpers,
    onError,
    onSuccess,
    operation,
    tools,
    url,
    values,
    // Dependents:
    method = toMethod(operation),
  } = params;

  const confirm: CrudListConfirmHelpers | undefined = params.confirm
    ? toConfirmHelpers(params.confirm)
    : tools?.confirm;

  const summary = getSummary?.(values);

  const props: ConfirmDialogProps = {
    actionProceedText: toProceedLabel(operation),
    content:
      description ??
      createElement(FormSummary, {
        entries: summary ?? values,
      }),
    onCancelAppend: () => helpers.setSubmitting(false),
    onProceedAppend: () => {
      confirm?.loading(true);

      const requestBody = getRequestBody?.(values, summary);

      api
        .request({
          data: requestBody,
          method,
          url,
        })
        .then(() => {
          confirm?.finish('Success', {
            children: onSuccess?.(),
          });

          tools?.add.open(false);
          tools?.edit.open(false);
        })
        .catch((error) => {
          const emsg = handleAPIError(error);

          emsg.children = createElement(
            Fragment,
            null,
            onError?.(error),
            ' ',
            emsg.children,
          );

          confirm?.finish('Error', emsg);
        });
    },
    proceedColour: operation === 'delete' ? 'red' : 'blue',
    titleText: header,
  };

  confirm?.prepare(props);

  confirm?.open(true);
};

export default handleFormSubmit;
