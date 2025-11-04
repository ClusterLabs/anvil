import { useCallback, useMemo, useRef, useState } from 'react';
import { toast } from 'react-toastify';

import ConfirmDialog from '../components/ConfirmDialog';

const useConfirmDialog = (
  args: {
    initial?: Partial<ConfirmDialogProps>;
  } = {},
): ConfirmDialogUtils => {
  const {
    initial: {
      actionProceedText = '',
      content = '',
      titleText = '',
      ...restInitialProps
    } = {},
  } = args;

  const confirmDialogRef = useRef<ConfirmDialogForwardedRefContent | null>(
    null,
  );

  const [confirmDialogProps, setConfirmDialogProps] =
    useState<ConfirmDialogProps>({
      actionProceedText,
      content,
      titleText,
    });

  const setConfirmDialogLoading = useCallback(
    (value: boolean) =>
      setConfirmDialogProps(({ loading, ...rest }) => ({
        ...rest,
        loading: value,
      })),
    [],
  );

  const setConfirmDialogOpen = useCallback(
    (value: boolean) => confirmDialogRef?.current?.setOpen?.(value),
    [],
  );

  const finishConfirm = useCallback(
    (title: React.ReactNode, message: Message) => {
      confirmDialogRef?.current?.setOpen?.(false);

      const type = /error/i.test(String(title)) ? 'error' : 'success';

      toast[type]<React.ReactNode>(message.children);
    },
    [],
  );

  const confirmDialog = useMemo<React.ReactElement>(
    () => (
      <ConfirmDialog
        {...restInitialProps}
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    ),
    [confirmDialogProps, restInitialProps],
  );

  return {
    confirmDialog,
    confirmDialogRef,
    setConfirmDialogLoading,
    setConfirmDialogOpen,
    setConfirmDialogProps,
    finishConfirm,
  };
};

export default useConfirmDialog;
