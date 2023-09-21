import { FC, useCallback, useContext, useMemo } from 'react';

import ActionGroup from '../ActionGroup';
import { DialogContext } from './Dialog';

const handleAction: ExtendableEventHandler<ButtonClickEventHandler> = (
  { handlers: { base, origin } },
  ...args
) => {
  base?.call(null, ...args);
  origin?.call(null, ...args);
};

const DialogActionGroup: FC<DialogActionGroupProps> = (props) => {
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

  const actions = useMemo(
    () => (
      <ActionGroup
        actions={[
          {
            ...cancelProps,
            children: cancelChildren,
            onClick: cancelHandler,
          },
          {
            background: proceedColour,
            ...proceedProps,
            children: proceedChildren,
            onClick: proceedHandler,
          },
        ]}
        loading={loading}
      />
    ),
    [
      cancelChildren,
      cancelHandler,
      cancelProps,
      loading,
      proceedChildren,
      proceedColour,
      proceedHandler,
      proceedProps,
    ],
  );

  return actions;
};

export default DialogActionGroup;
