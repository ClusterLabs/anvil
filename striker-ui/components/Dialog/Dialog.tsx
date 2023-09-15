import { Dialog as MuiDialog, SxProps, Theme } from '@mui/material';
import {
  ForwardRefExoticComponent,
  PropsWithChildren,
  ReactNode,
  RefAttributes,
  createContext,
  forwardRef,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import { Panel } from '../Panels';
import Spinner from '../Spinner';

const DialogContext = createContext<DialogContextContent | undefined>(
  undefined,
);

const Dialog: ForwardRefExoticComponent<
  PropsWithChildren<DialogProps> & RefAttributes<DialogForwardedRefContent>
> = forwardRef<DialogForwardedRefContent, DialogProps>((props, ref) => {
  const {
    children: externalChildren,
    dialogProps = {},
    loading,
    openInitially = false,
  } = props;

  const {
    // Do not initialize the external open state because we need it to
    // determine whether the dialog is controlled or uncontrolled.
    open: externalOpen,
    PaperProps: paperProps = {},
    ...restDialogProps
  } = dialogProps;

  const { sx: externalPaperSx, ...restPaperProps } = paperProps;

  const [controlOpen, setControlOpen] = useState<boolean>(openInitially);

  const open = useMemo<boolean>(
    () => externalOpen ?? controlOpen,
    [controlOpen, externalOpen],
  );

  const children = useMemo<ReactNode>(
    () => (loading ? <Spinner mt={0} /> : externalChildren),
    [externalChildren, loading],
  );

  const paperSx = useMemo<SxProps<Theme>>(
    () => ({
      overflow: 'visible',
      ...externalPaperSx,
    }),
    [externalPaperSx],
  );

  useImperativeHandle(
    ref,
    () => ({
      open,
      setOpen: setControlOpen,
    }),
    [open],
  );

  return (
    <MuiDialog
      open={open}
      PaperComponent={Panel}
      PaperProps={{ ...restPaperProps, sx: paperSx }}
      {...restDialogProps}
    >
      <DialogContext.Provider value={{ open, setOpen: setControlOpen }}>
        {children}
      </DialogContext.Provider>
    </MuiDialog>
  );
});

Dialog.displayName = 'Dialog';

export { DialogContext };

export default Dialog;
