type GateFormMessageKey = {
  accessError: string;
  identifierInputError: string;
  passphraseInputError: string;
};

type GateFormMessageSetter = (
  message?: import('../components/MessageBox').Message,
) => void;
type GateFormSubmittingSetter = (value: boolean) => void;

type GateFormSubmitHandler = (
  setMessage: GateFormMessageSetter,
  setIsSubmitting: GateFormSubmittingSetter,
  ...args: Parameters<DivFormEventHandler>
) => void;

type GateFormOptionalProps = {
  allowSubmit?: boolean;
  formContainer?: boolean;
  gridProps?: Partial<GridProps>;
  identifierId?: string;
  identifierInputTestBatchBuilder?: BuildInputTestBatchFunction;
  identifierOutlinedInputWithLabelProps?: Partial<
    import('../components/OutlinedInputWithLabel').OutlinedInputWithLabelProps
  >;
  onIdentifierBlurAppend?: import('../components/OutlinedInput').OutlinedInputProps['onBlur'];
  onSubmit?: DivFormEventHandler;
  onSubmitAppend?: GateFormSubmitHandler;
  passphraseId?: string;
  passphraseOutlinedInputWithLabelProps?: Partial<
    import('../components/OutlinedInputWithLabel').OutlinedInputWithLabelProps
  >;
};

type GateFormProps = GateFormOptionalProps & {
  identifierLabel: import('../components/OutlinedInputWithLabel').OutlinedInputWithLabelProps['label'];
  passphraseLabel: import('../components/OutlinedInputWithLabel').OutlinedInputWithLabelProps['label'];
  submitLabel: import('react').ReactNode;
};

type GateFormForwardedRefContent = {
  get?: () => { identifier: string; passphrase: string };
  messageGroup?: import('../components/MessageGroup').MessageGroupForwardedRefContent;
  setIsSubmitting?: GateFormSubmittingSetter;
};
