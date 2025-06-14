import { useCallback, useContext, useMemo } from 'react';

import { DialogContext } from './Dialog';
import IconButton from '../IconButton';
import { PanelHeader } from '../Panels';
import sxstring from '../../lib/sxstring';
import { HeaderText } from '../Text';

const DialogHeader: React.FC<React.PropsWithChildren<DialogHeaderProps>> = (
  props,
) => {
  const {
    children,
    onClose = ({ handlers: { base } }, ...args) => base?.call(null, ...args),
    showClose,
  } = props;

  const dialog = useContext(DialogContext);

  const closeHandler = useCallback<ButtonClickEventHandler>(
    (...args) =>
      onClose(
        {
          handlers: {
            base: () => {
              dialog?.setOpen(false);
            },
          },
        },
        ...args,
      ),
    [dialog, onClose],
  );

  const title = useMemo<React.ReactNode>(
    () => sxstring(children, HeaderText),
    [children],
  );

  const close = useMemo<React.ReactNode>(
    () =>
      showClose && (
        <IconButton mapPreset="close" onClick={closeHandler} size="small" />
      ),
    [closeHandler, showClose],
  );

  return (
    <PanelHeader>
      {title}
      {close}
    </PanelHeader>
  );
};

export default DialogHeader;
