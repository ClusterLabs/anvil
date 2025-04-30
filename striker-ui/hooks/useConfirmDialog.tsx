import { useCallback, useMemo, useRef, useState } from 'react';

import ConfirmDialog from '../components/ConfirmDialog';
import MessageBox from '../components/MessageBox';

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
    (value: boolean) => confirmDialogRef?.current?.setOpen?.call(null, value),
    [],
  );

  const finishConfirm = useCallback(
    (title: React.ReactNode, message: Message) =>
      setConfirmDialogProps({
        actionProceedText: '',
        content: <MessageBox {...message} />,
        showActionArea: false,
        showClose: true,
        titleText: title,
      }),
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
