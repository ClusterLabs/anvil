import { Box, Dialog } from '@mui/material';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import { BLUE, TEXT } from '../lib/consts/DEFAULT_THEME';

import ContainedButton from './ContainedButton';
import { Panel, PanelHeader } from './Panels';
import { BodyText, HeaderText } from './Text';

const ConfirmDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  ConfirmDialogProps
>(
  (
    {
      actionCancelText = 'Cancel',
      actionProceedText,
      content,
      dialogProps: { open: baseOpen = false, ...restDialogProps } = {},
      onCancelAppend,
      onProceedAppend,
      openInitially = false,
      proceedButtonProps = {},
      titleText,
    },
    ref,
  ) => {
    const { sx: proceedButtonSx } = proceedButtonProps;

    const [isOpen, setIsOpen] = useState<boolean>(openInitially);

    // TODO: using base open is depreciated; use internal state once all
    // dependent components finish the migrate.
    const open = useMemo(
      () => (ref ? isOpen : baseOpen),
      [baseOpen, isOpen, ref],
    );

    useImperativeHandle(
      ref,
      () => ({
        setOpen: (value) => setIsOpen(value),
      }),
      [],
    );

    return (
      <Dialog
        open={open}
        PaperComponent={Panel}
        PaperProps={{ sx: { overflow: 'visible' } }}
        {...restDialogProps}
      >
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
          <ContainedButton
            onClick={(...args) => {
              setIsOpen(false);

              onCancelAppend?.call(null, ...args);
            }}
          >
            {actionCancelText}
          </ContainedButton>
          <ContainedButton
            sx={{
              backgroundColor: BLUE,
              color: TEXT,

              '&:hover': { backgroundColor: `${BLUE}F0` },

              ...proceedButtonSx,
            }}
            onClick={(...args) => {
              setIsOpen(false);

              onProceedAppend?.call(null, ...args);
            }}
          >
            {actionProceedText}
          </ContainedButton>
        </Box>
      </Dialog>
    );
  },
);

ConfirmDialog.displayName = 'ConfirmDialog';

export default ConfirmDialog;
