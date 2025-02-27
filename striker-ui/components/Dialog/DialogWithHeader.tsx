import {
  ForwardRefExoticComponent,
  PropsWithChildren,
  RefAttributes,
  createContext,
  forwardRef,
  useMemo,
  useState,
} from 'react';

import Dialog from './Dialog';
import DialogHeader from './DialogHeader';

const DialogWithHeaderContext = createContext<DialogWithHeaderContext | null>(
  null,
);

const DialogWithHeader: ForwardRefExoticComponent<
  PropsWithChildren<DialogWithHeaderProps> &
    RefAttributes<DialogForwardedRefContent>
> = forwardRef<DialogForwardedRefContent, DialogWithHeaderProps>(
  (props, ref) => {
    const {
      children,
      dialogProps,
      header: initialHeader,
      loading,
      onClose,
      openInitially,
      showClose,
      wide,
    } = props;

    const [header, setHeader] = useState<React.ReactNode>(initialHeader);

    const context = useMemo<DialogWithHeaderContext>(
      () => ({
        setHeader,
      }),
      [],
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
  },
);

DialogWithHeader.displayName = 'DialogWithHeader';

export { DialogWithHeaderContext };

export default DialogWithHeader;
