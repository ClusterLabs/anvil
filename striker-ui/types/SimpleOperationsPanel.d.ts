type SimpleOperationsPanelOptionalProps = {
  onSubmit?: (
    props: Pick<
      ConfirmDialogProps,
      'actionProceedText' | 'content' | 'onProceedAppend' | 'titleText'
    >,
  ) => void;
  installTarget?: APIHostInstallTarget;
};

type SimpleOperationsPanelProps = SimpleOperationsPanelOptionalProps & {
  title: string;
};
