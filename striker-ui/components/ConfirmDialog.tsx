import { Box as MuiBox } from '@mui/material';
import {
  ForwardRefExoticComponent,
  PropsWithChildren,
  RefAttributes,
  createElement,
  forwardRef,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';

import {
  Dialog,
  DialogActionArea,
  DialogHeader,
  DialogScrollBox,
} from './Dialog';
import FlexBox from './FlexBox';
import sxstring from '../lib/sxstring';
import { BodyText } from './Text';

const ConfirmDialog: ForwardRefExoticComponent<
  PropsWithChildren<ConfirmDialogProps> &
    RefAttributes<ConfirmDialogForwardedRefContent>
> = forwardRef<ConfirmDialogForwardedRefContent, ConfirmDialogProps>(
  (
    {
      actionCancelText = 'Cancel',
      actionProceedText,
      children,
      closeOnProceed = false,
      contentContainerProps,
      dialogProps,
      disableProceed,
      loading,
      loadingAction = false,
      onActionAppend,
      onCancelAppend,
      onProceedAppend,
      openInitially,
      preActionArea,
      proceedButtonProps,
      proceedColour = 'blue',
      scrollContent = false,
      scrollBoxProps,
      showClose,
      titleText,
      // Dependents
      content = children,
    },
    ref,
  ) => {
    const dialogRef = useRef<DialogForwardedRefContent>(null);

    const contentElement = useMemo(
      () => sxstring(content, BodyText),
      [content],
    );

    const bodyElement = useMemo(
      () =>
        createElement(
          scrollContent ? DialogScrollBox : MuiBox,
          scrollBoxProps,
          contentElement,
        ),
      [contentElement, scrollBoxProps, scrollContent],
    );

    useImperativeHandle(
      ref,
      () => ({
        setOpen: (open) => dialogRef.current?.setOpen(open),
      }),
      [],
    );

    return (
      <Dialog
        dialogProps={dialogProps}
        loading={loading}
        openInitially={openInitially}
        ref={dialogRef}
      >
        <DialogHeader showClose={showClose}>{titleText}</DialogHeader>
        <FlexBox {...contentContainerProps}>
          {bodyElement}
          {preActionArea}
          <DialogActionArea
            cancelProps={{
              children: actionCancelText,
              onClick: (...args) => {
                onActionAppend?.call(null, ...args);
                onCancelAppend?.call(null, ...args);
              },
            }}
            closeOnProceed={closeOnProceed}
            loading={loadingAction}
            proceedProps={{
              background: proceedColour,
              children: actionProceedText,
              disabled: disableProceed,
              onClick: (...args) => {
                onActionAppend?.call(null, ...args);
                onProceedAppend?.call(null, ...args);
              },
              ...proceedButtonProps,
            }}
          />
        </FlexBox>
      </Dialog>
    );
  },
);

ConfirmDialog.displayName = 'ConfirmDialog';

export default ConfirmDialog;
