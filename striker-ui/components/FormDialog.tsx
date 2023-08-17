import { forwardRef, useMemo } from 'react';

import ConfirmDialog from './ConfirmDialog';
import IconButton from './IconButton';
import { HeaderText } from './Text';

const FormDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  ConfirmDialogProps & { showClose?: boolean }
>((props, ref) => {
  const { scrollContent, showClose, titleText, ...restProps } = props;

  const scrollBoxPaddingRight = useMemo(
    () => (scrollContent ? '.5em' : undefined),
    [scrollContent],
  );

  const titleElement = useMemo(() => {
    const title =
      typeof titleText === 'string' ? (
        <HeaderText>{titleText}</HeaderText>
      ) : (
        titleText
      );

    return showClose ? (
      <>
        {title}
        <IconButton
          mapPreset="close"
          onClick={() => {
            if (ref && 'current' in ref) {
              ref.current?.setOpen?.call(null, false);
            }
          }}
          variant="redcontained"
        />
      </>
    ) : (
      title
    );
  }, [ref, showClose, titleText]);

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
      scrollContent={scrollContent}
      titleText={titleElement}
      {...restProps}
      ref={ref}
    />
  );
});

FormDialog.defaultProps = {
  showClose: false,
};

FormDialog.displayName = 'FormDialog';

export default FormDialog;
