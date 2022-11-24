type ConfirmDialogOptionalProps = {
  actionCancelText?: string;
  dialogProps?: Partial<import('@mui/material').DialogProps>;
  onProceedAppend?: ContainedButtonProps['onClick'];
  onCancelAppend?: ContainedButtonProps['onClick'];
  openInitially?: boolean;
  proceedButtonProps?: ContainedButtonProps;
  proceedColour?: 'blue' | 'red';
};

type ConfirmDialogProps = ConfirmDialogOptionalProps & {
  actionProceedText: string;
  content: import('@mui/material').ReactNode;
  titleText: string;
};

type ConfirmDialogForwardedRefContent = {
  setOpen?: (value: boolean) => void;
};
