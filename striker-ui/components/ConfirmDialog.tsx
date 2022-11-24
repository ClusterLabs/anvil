import { Box, Dialog } from '@mui/material';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import { BLUE, RED, TEXT } from '../lib/consts/DEFAULT_THEME';

import ContainedButton from './ContainedButton';
import { Panel, PanelHeader } from './Panels';
import { BodyText, HeaderText } from './Text';

const MAP_TO_COLOUR: Record<
  Exclude<ConfirmDialogProps['proceedColour'], undefined>,
  string
> = {
  blue: BLUE,
  red: RED,
};

const ConfirmDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  ConfirmDialogProps
>(
  (
    {
      actionCancelText = 'Cancel',
      actionProceedText,
      content,
      dialogProps: {
        open: baseOpen = false,
        PaperProps: paperProps = {},
        ...restDialogProps
      } = {},
      onCancelAppend,
      onProceedAppend,
      openInitially = false,
      proceedButtonProps = {},
      proceedColour: proceedColourKey = 'blue',
      titleText,
    },
    ref,
  ) => {
    const { sx: paperSx, ...restPaperProps } = paperProps;
    const { sx: proceedButtonSx, ...restProceedButtonProps } =
      proceedButtonProps;

    const [isOpen, setIsOpen] = useState<boolean>(openInitially);

    // TODO: using base open is depreciated; use internal state once all
    // dependent components finish the migrate.
    const open = useMemo(
      () => (ref ? isOpen : baseOpen),
      [baseOpen, isOpen, ref],
    );
    const proceedColour = useMemo(
      () => MAP_TO_COLOUR[proceedColourKey],
      [proceedColourKey],
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
        PaperProps={{
          ...restPaperProps,
          sx: { overflow: 'visible', ...paperSx },
        }}
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
            onClick={(...args) => {
              setIsOpen(false);

              onProceedAppend?.call(null, ...args);
            }}
            {...restProceedButtonProps}
            sx={{
              backgroundColor: proceedColour,
              color: TEXT,

              '&:hover': { backgroundColor: `${proceedColour}F0` },

              ...proceedButtonSx,
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
