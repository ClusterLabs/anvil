type CommonUserInputGroupOptionalProps = {
  previous?: { name?: string; password?: string };
  readOnlyUserName?: boolean;
  requirePassword?: boolean;
  showPasswordField?: boolean;
};

type CommonUserInputGroupProps<M extends MapToInputTestID> =
  CommonUserInputGroupOptionalProps & {
    formUtils: FormUtils<M>;
  };
