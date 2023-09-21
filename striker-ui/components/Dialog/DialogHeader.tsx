import { FC, ReactNode, useContext, useMemo } from 'react';

import { DialogContext } from './Dialog';
import IconButton from '../IconButton';
import { PanelHeader } from '../Panels';
import sxstring from '../../lib/sxstring';
import { HeaderText } from '../Text';

const DialogHeader: FC<DialogHeaderProps> = (props) => {
  const { children, showClose } = props;

  const dialogContext = useContext(DialogContext);

  const title = useMemo<ReactNode>(
    () => sxstring(children, HeaderText),
    [children],
  );

  const close = useMemo<ReactNode>(
    () =>
      showClose && (
        <IconButton
          mapPreset="close"
          onClick={() => {
            dialogContext?.setOpen(false);
          }}
          size="small"
        />
      ),
    [dialogContext, showClose],
  );

  return (
    <PanelHeader>
      {title}
      {close}
    </PanelHeader>
  );
};

export default DialogHeader;
