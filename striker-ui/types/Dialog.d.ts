type DialogContextContent = {
  open: boolean;
  setOpen: (open: boolean) => void;
};

type DialogOptionalProps = {
  dialogProps?: Partial<import('@mui/material').DialogProps>;
  loading?: boolean;
  openInitially?: boolean;
  wide?: boolean;
};

type DialogProps = DialogOptionalProps;

type DialogForwardedRefContent = DialogContextContent;

/** DialogActionGroup */

type ButtonClickEventHandler = Exclude<
  ContainedButtonProps['onClick'],
  undefined
>;

type DialogActionGroupOptionalProps = {
  cancelChildren?: ContainedButtonProps['children'];
  cancelProps?: Partial<ContainedButtonProps>;
  closeOnProceed?: boolean;
  loading?: boolean;
  onCancel?: ExtendableEventHandler<ButtonClickEventHandler>;
  onProceed?: ExtendableEventHandler<ButtonClickEventHandler>;
  proceedChildren?: ContainedButtonProps['children'];
  proceedColour?: ContainedButtonProps['background'];
  proceedProps?: Partial<ContainedButtonProps>;
  showCancel?: boolean;
};

type DialogActionGroupProps = DialogActionGroupOptionalProps;

/** DialogHeader */

type DialogHeaderOptionalProps = {
  onClose?: ExtendableEventHandler<ButtonClickEventHandler>;
  showClose?: boolean;
};

type DialogHeaderProps = DialogHeaderOptionalProps;

/** DialogWithHeader */

type DialogWithHeaderProps = DialogProps &
  DialogHeaderProps & {
    header: import('react').ReactNode;
  };
