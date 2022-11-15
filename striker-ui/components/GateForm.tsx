import { SxProps, Theme } from '@mui/material';
import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from 'react';

import INPUT_TYPES from '../lib/consts/INPUT_TYPES';

import ContainedButton from './ContainedButton';
import FlexBox from './FlexBox';
import Grid from './Grid';
import InputWithRef, { InputForwardedRefContent } from './InputWithRef';
import MessageGroup, { MessageGroupForwardedRefContent } from './MessageGroup';
import OutlinedInputWithLabel from './OutlinedInputWithLabel';
import Spinner from './Spinner';

const INPUT_ROOT_SX: SxProps<Theme> = { width: '100%' };
const MESSAGE_KEY: GateFormMessageKey = { accessError: 'accessError' };

const GateForm = forwardRef<GateFormForwardedRefContent, GateFormProps>(
  (
    {
      allowSubmit: isAllowSubmit = true,
      gridProps: {
        columns: gridColumns = { xs: 1, sm: 2 },
        layout,
        spacing: gridSpacing = '1em',
        ...restGridProps
      } = {},
      identifierLabel,
      identifierOutlinedInputWithLabelProps: {
        formControlProps: identifierFormControlProps = {},
        ...restIdentifierOutlinedInputWithLabelProps
      } = {},
      onSubmit,
      onSubmitAppend,
      passphraseLabel,
      passphraseOutlinedInputWithLabelProps: {
        formControlProps: passphraseFormControlProps = {},
        inputProps: passphraseInputProps,
        ...restPassphraseOutlinedInputWithLabelProps
      } = {},
      submitLabel,
    },
    ref,
  ) => {
    const { sx: identifierSx, ...restIdentifierFormControlProps } =
      identifierFormControlProps;
    const { sx: passphraseSx, ...restPassphraseFormControlProps } =
      passphraseFormControlProps;

    const inputIdentifierRef = useRef<InputForwardedRefContent<'string'>>({});
    const inputPassphraseRef = useRef<InputForwardedRefContent<'string'>>({});
    const messageGroupRef = useRef<MessageGroupForwardedRefContent>({});

    const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
    const [isShowMessageGroup, setIsShowMessageGroup] =
      useState<boolean>(false);

    const setMessage: GateFormMessageSetter = useCallback(
      (message?, key = 'accessError') => {
        messageGroupRef.current.setMessage?.call(
          null,
          MESSAGE_KEY[key],
          message,
        );
      },
      [],
    );

    const messageGroupSxDisplay = useMemo(
      () => (isShowMessageGroup ? undefined : 'none'),
      [isShowMessageGroup],
    );
    const submitHandler: ContainedButtonProps['onClick'] = useMemo(
      () =>
        onSubmit ??
        ((...args) => {
          setMessage();
          setIsSubmitting(true);
          onSubmitAppend?.call(
            null,
            inputIdentifierRef.current,
            inputPassphraseRef.current,
            setMessage,
            setIsSubmitting,
            messageGroupRef.current,
            ...args,
          );
        }),
      [onSubmit, onSubmitAppend, setMessage],
    );
    const submitElement = useMemo(
      () =>
        isSubmitting ? (
          <Spinner sx={{ marginTop: 0 }} />
        ) : (
          <FlexBox row sx={{ justifyContent: 'flex-end' }}>
            <ContainedButton onClick={submitHandler}>
              {submitLabel}
            </ContainedButton>
          </FlexBox>
        ),
      [isSubmitting, submitHandler, submitLabel],
    );
    const submitGrid = useMemo(
      () =>
        isAllowSubmit
          ? {
              children: submitElement,
              sm: 2,
            }
          : undefined,
      [isAllowSubmit, submitElement],
    );

    useImperativeHandle(ref, () => ({
      get: () => ({
        identifier: inputIdentifierRef.current.getValue?.call(null) ?? '',
        passphrase: inputPassphraseRef.current.getValue?.call(null) ?? '',
      }),
      messageGroup: {
        ...messageGroupRef.current,
      },
      setIsSubmitting: (value) => {
        setIsSubmitting(value);
      },
    }));

    return (
      <Grid
        columns={gridColumns}
        layout={{
          'credential-identifier': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{
                      ...restIdentifierFormControlProps,
                      sx: { ...INPUT_ROOT_SX, ...identifierSx },
                    }}
                    label={identifierLabel}
                    {...restIdentifierOutlinedInputWithLabelProps}
                  />
                }
                ref={inputIdentifierRef}
              />
            ),
          },
          'credential-passphrase': {
            children: (
              <InputWithRef
                input={
                  <OutlinedInputWithLabel
                    formControlProps={{
                      ...restPassphraseFormControlProps,
                      sx: { ...INPUT_ROOT_SX, ...passphraseSx },
                    }}
                    inputProps={{
                      type: INPUT_TYPES.password,
                      ...passphraseInputProps,
                    }}
                    label={passphraseLabel}
                    {...restPassphraseOutlinedInputWithLabelProps}
                  />
                }
                ref={inputPassphraseRef}
              />
            ),
          },
          'credential-submit': submitGrid,
          'credential-message-group': {
            children: (
              <MessageGroup
                onSet={(length) => {
                  setIsShowMessageGroup(length > 0);
                }}
                ref={messageGroupRef}
              />
            ),
            sm: 2,
            sx: { display: messageGroupSxDisplay },
          },
        }}
        spacing={gridSpacing}
        {...restGridProps}
      />
    );
  },
);

GateForm.displayName = 'GateForm';

export default GateForm;
