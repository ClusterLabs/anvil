type DialogContextContent = {
  open: boolean;
  setOpen: (open: boolean) => void;
};

type DialogOptionalProps = {
  dialogProps?: Partial<import('@mui/material').DialogProps>;
  loading?: boolean;
  openInitially?: boolean;
};

type DialogProps = DialogOptionalProps;

type DialogForwardedRefContent = DialogContextContent;

/** DialogHeader */

type DialogHeaderOptionalProps = {
  showClose?: boolean;
};

type DialogHeaderProps = DialogHeaderOptionalProps;

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
};

type DialogActionGroupProps = DialogActionGroupOptionalProps;
