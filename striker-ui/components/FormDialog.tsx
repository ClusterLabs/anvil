import { BoxProps as MuiBoxProps } from '@mui/material';
import { forwardRef, useMemo } from 'react';

import ConfirmDialog from './ConfirmDialog';
import { FlexBoxProps } from './FlexBox';

const FormDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  React.PropsWithChildren<ConfirmDialogProps>
>((props, ref) => {
  const {
    children,
    contentContainerProps,
    dialogProps,
    onSubmitAppend,
    proceedButtonProps,
    scrollBoxProps,
    scrollContent,
    ...restProps
  } = props;

  const formBodyProps = useMemo<FlexBoxProps>(
    () => ({
      ...contentContainerProps,
      component: 'form',
      onSubmit: (...args) => {
        const [event] = args;

        event.preventDefault();

        onSubmitAppend?.call(null, ...args);
      },
    }),
    [contentContainerProps, onSubmitAppend],
  );

  const formScrollBoxProps = useMemo<MuiBoxProps>(
    () => ({
      ...scrollBoxProps,
      sx: scrollContent
        ? {
            overflowX: 'hidden',
            paddingTop: '.6em',
            ...scrollBoxProps?.sx,
          }
        : scrollBoxProps?.sx,
    }),
    [scrollBoxProps, scrollContent],
  );

  return (
    <ConfirmDialog
      dialogProps={dialogProps}
      contentContainerProps={formBodyProps}
      proceedButtonProps={{ ...proceedButtonProps, type: 'submit' }}
      scrollContent={scrollContent}
      scrollBoxProps={formScrollBoxProps}
      wide
      {...restProps}
      ref={ref}
    >
      {children}
    </ConfirmDialog>
  );
});

FormDialog.displayName = 'FormDialog';

export default FormDialog;
