type ConfirmDialogOptionalProps = {
  actionCancelText?: string;
  closeOnProceed?: boolean;
  contentContainerProps?: import('../components/FlexBox').FlexBoxProps;
  dialogProps?: Partial<import('@mui/material').DialogProps>;
  formContent?: boolean;
  loadingAction?: boolean;
  onActionAppend?: ContainedButtonProps['onClick'];
  onProceedAppend?: ContainedButtonProps['onClick'];
  onCancelAppend?: ContainedButtonProps['onClick'];
  onSubmitAppend?: import('react').FormEventHandler<HTMLDivElement>;
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
