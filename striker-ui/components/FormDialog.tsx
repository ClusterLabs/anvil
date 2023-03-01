import { forwardRef, useMemo } from 'react';

import ConfirmDialog from './ConfirmDialog';

const FormDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  ConfirmDialogProps
>((props, ref) => {
  const { scrollContent: isScrollContent } = props;

  const scrollBoxPaddingRight = useMemo(
    () => (isScrollContent ? '.5em' : undefined),
    [isScrollContent],
  );

  return (
    <ConfirmDialog
      dialogProps={{
        PaperProps: { sx: { minWidth: { xs: '90%', md: '50em' } } },
      }}
      formContent
      scrollBoxProps={{
        paddingRight: scrollBoxPaddingRight,
        paddingTop: '.3em',
      }}
      {...props}
      ref={ref}
    />
  );
});

FormDialog.displayName = 'FormDialog';

export default FormDialog;
