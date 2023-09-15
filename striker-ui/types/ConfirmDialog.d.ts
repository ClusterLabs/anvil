type DivFormEventHandler = import('react').FormEventHandler<HTMLDivElement>;
type DivFormEventHandlerParameters = Parameters<DivFormEventHandler>;

type ConfirmDialogOptionalProps = {
  actionCancelText?: string;
  closeOnProceed?: boolean;
  content?: import('react').ReactNode;
  contentContainerProps?: import('../components/FlexBox').FlexBoxProps;
  disableProceed?: boolean;
  loadingAction?: boolean;
  onActionAppend?: ContainedButtonProps['onClick'];
  onCancelAppend?: ContainedButtonProps['onClick'];
  onProceedAppend?: ContainedButtonProps['onClick'];
  onSubmitAppend?: DivFormEventHandler;
  preActionArea?: import('react').ReactNode;
  proceedButtonProps?: ContainedButtonProps;
  proceedColour?: 'blue' | 'red';
  scrollContent?: boolean;
  scrollBoxProps?: import('@mui/material').BoxProps;
};

type ConfirmDialogProps = Omit<DialogWithHeaderProps, 'header'> &
  ConfirmDialogOptionalProps & {
    actionProceedText: string;
    titleText: import('react').ReactNode;
  };

type ConfirmDialogForwardedRefContent = {
  setOpen?: (value: boolean) => void;
};
