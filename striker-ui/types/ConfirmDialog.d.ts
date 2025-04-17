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
  showActionArea?: boolean;
};

type ConfirmDialogProps = Omit<DialogWithHeaderProps, 'header'> &
  Pick<DialogActionGroupProps, 'showCancel'> &
  ConfirmDialogOptionalProps & {
    actionProceedText: string;
    titleText: import('react').ReactNode;
  };

type ConfirmDialogForwardedRefContent = {
  setOpen?: (value: boolean) => void;
};

type ConfirmDialogUtils = {
  confirmDialog: React.ReactElement;
  confirmDialogRef: React.MutableRefObject<ConfirmDialogForwardedRefContent | null>;
  setConfirmDialogLoading: (value: boolean) => void;
  setConfirmDialogOpen: (value: boolean) => void;
  setConfirmDialogProps: React.Dispatch<
    React.SetStateAction<ConfirmDialogProps>
  >;
  finishConfirm: (title: React.ReactNode, message: Message) => void;
};
