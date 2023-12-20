import {
  Dispatch,
  MutableRefObject,
  ReactElement,
  ReactNode,
  SetStateAction,
  useCallback,
  useMemo,
  useRef,
  useState,
} from 'react';

import ConfirmDialog from '../components/ConfirmDialog';
import MessageBox from '../components/MessageBox';

const useConfirmDialog = (
  args: {
    initial?: Partial<ConfirmDialogProps>;
  } = {},
): {
  confirmDialog: ReactElement;
  confirmDialogRef: MutableRefObject<ConfirmDialogForwardedRefContent | null>;
  setConfirmDialogOpen: (value: boolean) => void;
  setConfirmDialogProps: Dispatch<SetStateAction<ConfirmDialogProps>>;
  finishConfirm: (title: ReactNode, message: Message) => void;
} => {
  const {
    initial: { actionProceedText = '', content = '', titleText = '' } = {},
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

  const setConfirmDialogOpen = useCallback(
    (value: boolean) => confirmDialogRef?.current?.setOpen?.call(null, value),
    [],
  );

  const finishConfirm = useCallback(
    (title: ReactNode, message: Message) =>
      setConfirmDialogProps({
        actionProceedText: '',
        content: <MessageBox {...message} />,
        showActionArea: false,
        showClose: true,
        titleText: title,
      }),
    [],
  );

  const confirmDialog = useMemo<ReactElement>(
    () => <ConfirmDialog {...confirmDialogProps} ref={confirmDialogRef} />,
    [confirmDialogProps],
  );

  return {
    confirmDialog,
    confirmDialogRef,
    setConfirmDialogOpen,
    setConfirmDialogProps,
    finishConfirm,
  };
};

export default useConfirmDialog;