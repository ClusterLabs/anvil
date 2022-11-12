type ConfirmDialogOptionalProps = {
  actionCancelText?: string;
  dialogProps?: import('@mui/material').DialogProps;
  onCancelAppend?: ContainedButtonProps['onClick'];
  openInitially?: boolean;
  proceedButtonProps?: ContainedButtonProps;
};

type ConfirmDialogProps = ConfirmDialogOptionalProps & {
  actionProceedText: string;
  content: import('@mui/material').ReactNode;
  onProceedAppend: Exclude<ContainedButtonProps['onClick'], undefined>;
  titleText: string;
};

type ConfirmDialogForwardedRefContent = {
  setOpen?: (value: boolean) => void;
};
