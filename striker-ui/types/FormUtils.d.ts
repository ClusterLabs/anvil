type FormValidity<T> = {
  [K in keyof T]?: boolean;
};

type InputTestBatchFinishCallbackBuilder<M extends MapToInputTestID> = (
  key: keyof M,
) => InputTestBatchFinishCallback;

type InputFirstRenderFunctionArgs = { isValid: boolean };

type InputFirstRenderFunction = (args: InputFirstRenderFunctionArgs) => void;

type InputFirstRenderFunctionBuilder<M extends MapToInputTestID> = (
  key: keyof M,
) => InputFirstRenderFunction;

type InputUnmountFunction = () => void;

type InputUnmountFunctionBuilder<M extends MapToInputTestID> = (
  key: keyof M,
) => InputUnmountFunction;

type SubmitFormFunction = (args: {
  body: Record<string, unknown>;
  getErrorMsg: (
    parentMsg: import('react').ReactNode,
  ) => import('react').ReactNode;
  msgKey?: string;
  method: 'delete' | 'post' | 'put';
  onError?: () => void;
  onSuccess?: () => void;
  setMsg?: import('../components/MessageGroup').MessageGroupForwardedRefContent['setMessage'];
  successMsg?: import('react').ReactNode;
  url: string;
}) => void;

type FormUtils<M extends MapToInputTestID> = {
  buildFinishInputTestBatchFunction: InputTestBatchFinishCallbackBuilder<M>;
  buildInputFirstRenderFunction: InputFirstRenderFunctionBuilder<M>;
  buildInputUnmountFunction: InputUnmountFunctionBuilder<M>;
  formValidity: FormValidity<M>;
  isFormInvalid: boolean;
  isFormSubmitting: boolean;
  setApiMessage: (message?: Message) => void;
  setFormValidity: (value: FormValidity<M>) => void;
  setMessage: (key: keyof M, message?: Message) => void;
  setMessageRe: (re: RegExp, message?: Message) => void;
  setValidity: (key: keyof M, value?: boolean) => void;
  setValidityRe: (re: RegExp, value?: boolean) => void;
  submitForm: SubmitFormFunction;
  unsetKey: (key: keyof M) => void;
  unsetKeyRe: (re: RegExp) => void;
};
