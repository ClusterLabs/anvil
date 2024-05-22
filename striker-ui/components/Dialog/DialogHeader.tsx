import { FC, ReactNode, useCallback, useContext, useMemo } from 'react';

import { DialogContext } from './Dialog';
import IconButton from '../IconButton';
import { PanelHeader } from '../Panels';
import sxstring from '../../lib/sxstring';
import { HeaderText } from '../Text';

const DialogHeader: FC<DialogHeaderProps> = (props) => {
  const {
    children,
    onClose = ({ handlers: { base } }, ...args) => base?.call(null, ...args),
    showClose,
  } = props;

  const dialogContext = useContext(DialogContext);

  const closeHandler = useCallback<ButtonClickEventHandler>(
    (...args) =>
      onClose(
        {
          handlers: {
            base: () => {
              dialogContext?.setOpen(false);
            },
          },
        },
        ...args,
      ),
    [dialogContext, onClose],
  );

  const title = useMemo<ReactNode>(
    () => sxstring(children, HeaderText),
    [children],
  );

  const close = useMemo<ReactNode>(
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
