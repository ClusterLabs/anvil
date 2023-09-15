import { styled } from '@mui/material';
import { FC, useCallback, useContext, useMemo } from 'react';

import ContainedButton from '../ContainedButton';
import { DialogContext } from './Dialog';
import FlexBox from '../FlexBox';
import Spinner from '../Spinner';

const FlexEndBox = styled(FlexBox)({
  justifyContent: 'flex-end',
  width: '100%',
});

const handleAction: ExtendableEventHandler<ButtonClickEventHandler> = (
  { handlers: { base, origin } },
  ...args
) => {
  base?.call(null, ...args);
  origin?.call(null, ...args);
};

const DialogActionArea: FC<DialogActionAreaProps> = (props) => {
  const {
    cancelProps,
    closeOnProceed,
    loading = false,
    onCancel = handleAction,
    onProceed = handleAction,
    proceedColour,
    proceedProps,
    // Dependents
    cancelChildren = cancelProps?.children,
    proceedChildren = proceedProps?.children,
  } = props;

  const dialogContext = useContext(DialogContext);

  const cancelHandler = useCallback<ButtonClickEventHandler>(
    (...args) =>
      onCancel(
        {
          handlers: {
            base: () => {
              dialogContext?.setOpen(false);
            },
            origin: cancelProps?.onClick,
          },
        },
        ...args,
      ),
    [cancelProps?.onClick, dialogContext, onCancel],
  );

  const proceedHandler = useCallback<ButtonClickEventHandler>(
    (...args) =>
      onProceed(
        {
          handlers: {
            base: () => {
              if (closeOnProceed) {
                dialogContext?.setOpen(false);
              }
            },
            origin: proceedProps?.onClick,
          },
        },
        ...args,
      ),
    [closeOnProceed, dialogContext, onProceed, proceedProps?.onClick],
  );

  const cancelButton = useMemo(
    () => (
      <ContainedButton {...cancelProps} onClick={cancelHandler}>
        {cancelChildren}
      </ContainedButton>
    ),
    [cancelChildren, cancelHandler, cancelProps],
  );

  const proceedButton = useMemo(
    () => (
      <ContainedButton
        background={proceedColour}
        {...proceedProps}
        onClick={proceedHandler}
      >
        {proceedChildren}
      </ContainedButton>
    ),
    [proceedChildren, proceedColour, proceedHandler, proceedProps],
  );

  const actions = useMemo(
    () => (
      <FlexEndBox row spacing=".5em">
        {cancelButton}
        {proceedButton}
      </FlexEndBox>
    ),
    [cancelButton, proceedButton],
  );

  const actionArea = useMemo(
    () => (loading ? <Spinner mt={0} /> : actions),
    [actions, loading],
  );

  return actionArea;
};

export default DialogActionArea;
