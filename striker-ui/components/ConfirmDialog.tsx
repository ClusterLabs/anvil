import { MouseEventHandler, ReactNode } from 'react';
import { Box, ButtonProps, Dialog, DialogProps } from '@mui/material';

import ContainedButton from './ContainedButton';
import { Panel, PanelHeader } from './Panels';
import { BodyText, HeaderText } from './Text';

type ConfirmDialogProps = {
  actionCancelText?: string;
  actionProceedText: string;
  content: ReactNode | string;
  dialogProps: DialogProps;
  onCancel: MouseEventHandler<HTMLButtonElement>;
  onProceed: MouseEventHandler<HTMLButtonElement>;
  proceedButtonProps?: ButtonProps;
  titleText: string;
};

const CONFIRM_DIALOG_DEFAULT_PROPS = {
  actionCancelText: 'Cancel',
  proceedButtonProps: { sx: undefined },
};

const ConfirmDialog = (
  {
    actionCancelText,
    actionProceedText,
    content,
    dialogProps: { open },
    onCancel,
    onProceed,
    proceedButtonProps,
    titleText,
  }: ConfirmDialogProps = CONFIRM_DIALOG_DEFAULT_PROPS as ConfirmDialogProps,
): JSX.Element => {
  const { sx: proceedButtonSx } =
    proceedButtonProps ?? CONFIRM_DIALOG_DEFAULT_PROPS.proceedButtonProps;

  return (
    <Dialog {...{ open }} PaperComponent={Panel}>
      <PanelHeader>
        <HeaderText text={titleText} />
      </PanelHeader>
      <Box sx={{ marginBottom: '1em' }}>
        {typeof content === 'string' ? <BodyText text={content} /> : content}
      </Box>
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'row',
          justifyContent: 'flex-end',
          width: '100%',

          '& > :not(:first-child)': {
            marginLeft: '.5em',
          },
        }}
      >
        <ContainedButton onClick={onCancel}>{actionCancelText}</ContainedButton>
        <ContainedButton sx={proceedButtonSx} onClick={onProceed}>
          {actionProceedText}
        </ContainedButton>
      </Box>
    </Dialog>
  );
};

ConfirmDialog.defaultProps = CONFIRM_DIALOG_DEFAULT_PROPS;

export default ConfirmDialog;
