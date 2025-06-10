import { createContext, forwardRef, useMemo, useState } from 'react';

import Dialog from './Dialog';
import DialogHeader from './DialogHeader';

const DialogWithHeaderContext = createContext<DialogWithHeaderContext | null>(
  null,
);

const DialogWithHeader: React.ForwardRefExoticComponent<
  React.PropsWithChildren<DialogWithHeaderProps> &
    React.RefAttributes<DialogForwardedRefContent>
> = forwardRef<
  DialogForwardedRefContent,
  React.PropsWithChildren<DialogWithHeaderProps>
>((props, ref) => {
  const {
    children,
    dialogProps,
    header: externalHeader,
    loading,
    onClose,
    openInitially,
    showClose,
    wide,
  } = props;

  const [internalHeader, setInternalHeader] =
    useState<React.ReactNode>(externalHeader);

  const context = useMemo<DialogWithHeaderContext>(
    () => ({
      setHeader: setInternalHeader,
    }),
    [],
  );

  const header = useMemo<React.ReactNode>(
    () => externalHeader || internalHeader,
    [externalHeader, internalHeader],
  );

  return (
    <DialogWithHeaderContext.Provider value={context}>
      <Dialog
        dialogProps={dialogProps}
        loading={loading}
        openInitially={openInitially}
        ref={ref}
        wide={wide}
      >
        <DialogHeader onClose={onClose} showClose={showClose}>
          {header}
        </DialogHeader>
        {children}
      </Dialog>
    </DialogWithHeaderContext.Provider>
  );
});

DialogWithHeader.displayName = 'DialogWithHeader';

export { DialogWithHeaderContext };

export default DialogWithHeader;
