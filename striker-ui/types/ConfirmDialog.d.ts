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
  scrollContent?: boolean;
  scrollBoxProps?: import('@mui/material').BoxProps;
};

type ConfirmDialogProps = ConfirmDialogOptionalProps & {
  actionProceedText: string;
  content: import('react').ReactNode;
  titleText: import('react').ReactNode;
};

type ConfirmDialogForwardedRefContent = {
  setOpen?: (value: boolean) => void;
};
