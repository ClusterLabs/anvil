import {
  DialogProps as MuiDialogProps,
  Dialog as MuiDialog,
} from '@mui/material';
import { merge } from 'lodash';
import {
  createContext,
  forwardRef,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import { Panel } from '../Panels';
import Spinner from '../Spinner';

const DialogContext = createContext<DialogContext | null>(null);

const Dialog: React.ForwardRefExoticComponent<
  React.PropsWithChildren<DialogProps> &
    React.RefAttributes<DialogForwardedRefContent>
> = forwardRef<DialogForwardedRefContent, React.PropsWithChildren<DialogProps>>(
  (props, ref) => {
    const {
      children: externalChildren,
      dialogProps,
      loading,
      onTransitionExited,
      openInitially = false,
      wide,
    } = props;

    // Do not initialize the external open state because we need it to
    // determine whether the dialog is controlled or uncontrolled.

    const [controlOpen, setControlOpen] = useState<boolean>(openInitially);

    const muiDialogProps = useMemo<MuiDialogProps>(() => {
      const minWidth = wide
        ? {
            xs: 'calc(100%)',
            md: '50em',
          }
        : undefined;

      return merge(
        {
          open: controlOpen,
          PaperComponent: Panel,
          PaperProps: {
            sx: {
              minWidth,
              overflow: 'visible',
            },
          },
          TransitionProps: {
            onExited: onTransitionExited,
          },
        },
        dialogProps,
      );
    }, [controlOpen, dialogProps, onTransitionExited, wide]);

    const children = useMemo<React.ReactNode>(
      () => (loading ? <Spinner mt={0} /> : externalChildren),
      [externalChildren, loading],
    );

    useImperativeHandle(
      ref,
      () => ({
        open: muiDialogProps.open,
        setOpen: setControlOpen,
      }),
      [muiDialogProps.open],
    );

    return (
      <MuiDialog {...muiDialogProps}>
        <DialogContext.Provider
          value={{
            open: muiDialogProps.open,
            setOpen: setControlOpen,
          }}
        >
          {children}
        </DialogContext.Provider>
      </MuiDialog>
    );
  },
);

Dialog.displayName = 'Dialog';

export { DialogContext };

export default Dialog;
