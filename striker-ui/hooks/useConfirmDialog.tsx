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
  setConfirmDialogLoading: (value: boolean) => void;
  setConfirmDialogOpen: (value: boolean) => void;
  setConfirmDialogProps: Dispatch<SetStateAction<ConfirmDialogProps>>;
  finishConfirm: (title: ReactNode, message: Message) => void;
} => {
  const {
    initial: {
      actionProceedText = '',
      closeOnProceed,
      content = '',
      titleText = '',
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
    () => (
      <ConfirmDialog
        closeOnProceed={closeOnProceed}
        {...confirmDialogProps}
        ref={confirmDialogRef}
      />
    ),
    [closeOnProceed, confirmDialogProps],
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
