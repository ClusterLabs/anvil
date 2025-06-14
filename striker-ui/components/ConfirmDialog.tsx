import { Box as MuiBox } from '@mui/material';
import {
  createElement,
  forwardRef,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';

import { DialogActionArea, DialogScrollBox, DialogWithHeader } from './Dialog';
import FlexBox from './FlexBox';
import sxstring from '../lib/sxstring';
import { BodyText } from './Text';

const ConfirmDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  React.PropsWithChildren<ConfirmDialogProps>
>(
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
      showActionArea = true,
      showCancel,
      showClose,
      titleText,
      wide,
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

    const actionArea = useMemo(
      () =>
        showActionArea && (
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
            showCancel={showCancel}
          />
        ),
      [
        actionCancelText,
        actionProceedText,
        closeOnProceed,
        disableProceed,
        loadingAction,
        onActionAppend,
        onCancelAppend,
        onProceedAppend,
        proceedButtonProps,
        proceedColour,
        showActionArea,
        showCancel,
      ],
    );

    useImperativeHandle(
      ref,
      () => ({
        setOpen: (open) => dialogRef.current?.setOpen(open),
      }),
      [],
    );

    return (
      <DialogWithHeader
        dialogProps={dialogProps}
        header={titleText}
        loading={loading}
        openInitially={openInitially}
        ref={dialogRef}
        showClose={showClose}
        wide={wide}
      >
        <FlexBox {...contentContainerProps}>
          {bodyElement}
          {preActionArea}
          {actionArea}
        </FlexBox>
      </DialogWithHeader>
    );
  },
);

ConfirmDialog.displayName = 'ConfirmDialog';

export default ConfirmDialog;
