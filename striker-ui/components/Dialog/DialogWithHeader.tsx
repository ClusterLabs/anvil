import {
  ForwardRefExoticComponent,
  PropsWithChildren,
  RefAttributes,
  forwardRef,
} from 'react';

import Dialog from './Dialog';
import DialogHeader from './DialogHeader';

const DialogWithHeader: ForwardRefExoticComponent<
  PropsWithChildren<DialogWithHeaderProps> &
    RefAttributes<DialogForwardedRefContent>
> = forwardRef<DialogForwardedRefContent, DialogWithHeaderProps>(
  (props, ref) => {
    const {
      children,
      dialogProps,
      header,
      loading,
      openInitially,
      showClose,
      wide,
    } = props;

    return (
      <Dialog
        dialogProps={dialogProps}
        loading={loading}
        openInitially={openInitially}
        ref={ref}
        wide={wide}
      >
        <DialogHeader showClose={showClose}>{header}</DialogHeader>
        {children}
      </Dialog>
    );
  },
);

DialogWithHeader.displayName = 'DialogWithHeader';

export default DialogWithHeader;
