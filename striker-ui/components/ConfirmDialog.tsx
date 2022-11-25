import { Box, Dialog } from '@mui/material';
import { forwardRef, useImperativeHandle, useMemo, useState } from 'react';

import { BLUE, RED, TEXT } from '../lib/consts/DEFAULT_THEME';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
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
      closeOnProceed: isCloseOnProceed = false,
      content,
      dialogProps: {
        open: baseOpen = false,
        PaperProps: paperProps = {},
        ...restDialogProps
      } = {},
      loadingAction: isLoadingAction = false,
      onActionAppend,
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

    const cancelButtonElement = useMemo(
      () => (
        <ContainedButton
          onClick={(...args) => {
            setIsOpen(false);

            onActionAppend?.call(null, ...args);
            onCancelAppend?.call(null, ...args);
          }}
        >
          {actionCancelText}
        </ContainedButton>
      ),
      [actionCancelText, onActionAppend, onCancelAppend],
    );
    const proceedButtonElement = useMemo(
      () => (
        <ContainedButton
          onClick={(...args) => {
            if (isCloseOnProceed) {
              setIsOpen(false);
            }

            onActionAppend?.call(null, ...args);
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
      ),
      [
        actionProceedText,
        isCloseOnProceed,
        onActionAppend,
        onProceedAppend,
        proceedButtonSx,
        proceedColour,
        restProceedButtonProps,
      ],
    );
    const actionAreaElement = useMemo(
      () =>
        isLoadingAction ? (
          <Spinner mt={0} />
        ) : (
          <FlexBox
            row
            spacing=".5em"
            sx={{ justifyContent: 'flex-end', width: '100%' }}
          >
            {cancelButtonElement}
            {proceedButtonElement}
          </FlexBox>
        ),
      [cancelButtonElement, isLoadingAction, proceedButtonElement],
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
        {actionAreaElement}
      </Dialog>
    );
  },
);

ConfirmDialog.displayName = 'ConfirmDialog';

export default ConfirmDialog;
