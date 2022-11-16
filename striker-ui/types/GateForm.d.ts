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
  identifierContent: import('../components/InputWithRef').InputForwardedRefContent<'string'>,
  passphraseContent: import('../components/InputWithRef').InputForwardedRefContent<'string'>,
  setMessage: GateFormMessageSetter,
  setIsSubmitting: GateFormSubmittingSetter,
  messageGroupContent: import('../components/MessageGroup').MessageGroupForwardedRefContent,
  ...args: Parameters<ContainedButtonProps['onClick']>
) => void;

type GateFormOptionalProps = {
  allowSubmit?: boolean;
  gridProps?: Partial<GridProps>;
  identifierOutlinedInputWithLabelProps?: Partial<
    import('../components/OutlinedInputWithLabel').OutlinedInputWithLabelProps
  >;
  identifierInputTestBatchBuilder?: (
    setMessage: GateFormMessageSetter,
    identifierContent: import('../components/InputWithRef').InputForwardedRefContent<'string'>,
  ) => ReturnType<BuildInputTestBatchFunction>;
  onSubmit?: ContainedButtonProps['onClick'];
  onSubmitAppend?: GateFormSubmitHandler;
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
