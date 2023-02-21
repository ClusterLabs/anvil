import { Box, Dialog as MUIDialog, SxProps, Theme } from '@mui/material';
import {
  ButtonHTMLAttributes,
  ElementType,
  FormEventHandler,
  forwardRef,
  MouseEventHandler,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import { BLUE, RED, TEXT } from '../lib/consts/DEFAULT_THEME';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import { Panel, PanelHeader } from './Panels';
import Spinner from './Spinner';
import { BodyText, HeaderText } from './Text';

const MAP_TO_COLOUR: Record<
  Exclude<ConfirmDialogProps['proceedColour'], undefined>,
  string
> = {
  blue: BLUE,
  red: RED,
};

const ConfirmDialog = forwardRef<
  ConfirmDialogForwardedRefContent,
  ConfirmDialogProps
>(
  (
    {
      actionCancelText = 'Cancel',
      actionProceedText,
      contentContainerProps = {},
      closeOnProceed: isCloseOnProceed = false,
      content,
      dialogProps: {
        open: baseOpen = false,
        PaperProps: paperProps = {},
        ...restDialogProps
      } = {},
      formContent: isFormContent,
      loadingAction: isLoadingAction = false,
      onActionAppend,
      onCancelAppend,
      onProceedAppend,
      onSubmitAppend,
      openInitially = false,
      proceedButtonProps = {},
      proceedColour: proceedColourKey = 'blue',
      scrollContent: isScrollContent = false,
      scrollBoxProps: { sx: scrollBoxSx, ...restScrollBoxProps } = {},
      titleText,
    },
    ref,
  ) => {
    const { sx: paperSx, ...restPaperProps } = paperProps;
    const { sx: proceedButtonSx, ...restProceedButtonProps } =
      proceedButtonProps;

    const [isOpen, setIsOpen] = useState<boolean>(openInitially);

    // TODO: using base open is depreciated; use internal state once all
    // dependent components finish the migrate.
    const open = useMemo(
      () => (ref ? isOpen : baseOpen),
      [baseOpen, isOpen, ref],
    );
    const proceedColour = useMemo(
      () => MAP_TO_COLOUR[proceedColourKey],
      [proceedColourKey],
    );
    const {
      contentContainerComponent,
      contentContainerSubmitEventHandler,
      proceedButtonClickEventHandler,
      proceedButtonType,
    } = useMemo(() => {
      let ccComponent: ElementType | undefined;
      let ccSubmitEventHandler: FormEventHandler<HTMLDivElement> | undefined;
      let pbClickEventHandler:
        | MouseEventHandler<HTMLButtonElement>
        | undefined = (...args) => {
        if (isCloseOnProceed) {
          setIsOpen(false);
        }

        onActionAppend?.call(null, ...args);
        onProceedAppend?.call(null, ...args);
      };
      let pbType: ButtonHTMLAttributes<HTMLButtonElement>['type'] | undefined;

      if (isFormContent) {
        ccComponent = 'form';
        ccSubmitEventHandler = (event, ...restArgs) => {
          event.preventDefault();

          if (isCloseOnProceed) {
            setIsOpen(false);
          }

          onSubmitAppend?.call(null, event, ...restArgs);
        };
        pbClickEventHandler = undefined;
        pbType = 'submit';
      }

      return {
        contentContainerComponent: ccComponent,
        contentContainerSubmitEventHandler: ccSubmitEventHandler,
        proceedButtonClickEventHandler: pbClickEventHandler,
        proceedButtonType: pbType,
      };
    }, [
      isCloseOnProceed,
      isFormContent,
      onActionAppend,
      onProceedAppend,
      onSubmitAppend,
    ]);

    const cancelButtonElement = useMemo(
      () => (
        <ContainedButton
          onClick={(...args) => {
            setIsOpen(false);

            onActionAppend?.call(null, ...args);
            onCancelAppend?.call(null, ...args);
          }}
        >
          {actionCancelText}
        </ContainedButton>
      ),
      [actionCancelText, onActionAppend, onCancelAppend],
    );
    const proceedButtonElement = useMemo(
      () => (
        <ContainedButton
          onClick={proceedButtonClickEventHandler}
          type={proceedButtonType}
          {...restProceedButtonProps}
          sx={{
            backgroundColor: proceedColour,
            color: TEXT,

            '&:hover': { backgroundColor: `${proceedColour}F0` },

            ...proceedButtonSx,
          }}
        >
          {actionProceedText}
        </ContainedButton>
      ),
      [
        actionProceedText,
        proceedButtonClickEventHandler,
        proceedButtonSx,
        proceedButtonType,
        proceedColour,
        restProceedButtonProps,
      ],
    );

    const actionAreaElement = useMemo(
      () =>
        isLoadingAction ? (
          <Spinner mt={0} />
        ) : (
          <FlexBox
            row
            spacing=".5em"
            sx={{ justifyContent: 'flex-end', width: '100%' }}
          >
            {cancelButtonElement}
            {proceedButtonElement}
          </FlexBox>
        ),
      [cancelButtonElement, isLoadingAction, proceedButtonElement],
    );
    const contentElement = useMemo(
      () =>
        typeof content === 'string' ? <BodyText text={content} /> : content,
      [content],
    );
    const headerElement = useMemo(
      () =>
        typeof titleText === 'string' ? (
          <HeaderText>{titleText}</HeaderText>
        ) : (
          titleText
        ),
      [titleText],
    );
    const combinedScrollBoxSx = useMemo<SxProps<Theme> | undefined>(
      () =>
        isScrollContent
          ? {
              maxHeight: '60vh',
              overflowY: 'scroll',
              padding: '.3em .5em',
              ...scrollBoxSx,
            }
          : undefined,
      [isScrollContent, scrollBoxSx],
    );

    useImperativeHandle(
      ref,
      () => ({
        setOpen: (value) => setIsOpen(value),
      }),
      [],
    );

    return (
      <MUIDialog
        open={open}
        PaperComponent={Panel}
        PaperProps={{
          ...restPaperProps,
          sx: { overflow: 'visible', ...paperSx },
        }}
        {...restDialogProps}
      >
        <PanelHeader>{headerElement}</PanelHeader>
        <FlexBox
          component={contentContainerComponent}
          onSubmit={contentContainerSubmitEventHandler}
          {...contentContainerProps}
        >
          <Box {...restScrollBoxProps} sx={combinedScrollBoxSx}>
            {contentElement}
          </Box>
          {actionAreaElement}
        </FlexBox>
      </MUIDialog>
    );
  },
);

ConfirmDialog.displayName = 'ConfirmDialog';

export default ConfirmDialog;
