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

type FormUtils<M extends MapToInputTestID> = {
  buildFinishInputTestBatchFunction: InputTestBatchFinishCallbackBuilder<M>;
  buildInputFirstRenderFunction: InputFirstRenderFunctionBuilder<M>;
  formValidity: FormValidity<M>;
  isFormInvalid: boolean;
  msgSetters: MapToMessageSetter<M>;
  setFormValidity: import('react').Dispatch<
    import('react').SetStateAction<FormValidity<M>>
  >;
  setMsgSetter: (
    id: keyof M,
    setter?: MessageSetter,
    options?: { isOverwrite?: boolean },
  ) => void;
  setValidity: (key: keyof M, value?: boolean) => void;
  setValidityRe: (re: RegExp, value?: boolean) => void;
};
