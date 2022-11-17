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
import {
  buildPeacefulStringTestBatch,
  createTestInputFunction,
} from '../lib/test_input';

const INPUT_ROOT_SX: SxProps<Theme> = { width: '100%' };
const IT_IDS = {
  identifier: 'identifier',
  passphrase: 'passphrase',
};
const MESSAGE_KEY: GateFormMessageKey = {
  accessError: 'accessError',
  identifierInputError: 'identifierInputError',
  passphraseInputError: 'passphraseInputError',
};

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
        inputProps: identifierInputProps,
        ...restIdentifierOutlinedInputWithLabelProps
      } = {},
      identifierInputTestBatchBuilder: overwriteIdentifierInputTestBatch,
      onIdentifierBlurAppend,
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

    const [isInputIdentifierValid, setIsInputIdentifierValid] =
      useState<boolean>(false);
    const [isInputPassphraseValid, setIsInputPassphraseValid] =
      useState<boolean>(false);
    const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

    const setAccessErrorMessage: GateFormMessageSetter = useCallback(
      (message?) => {
        messageGroupRef.current.setMessage?.call(
          null,
          MESSAGE_KEY.accessError,
          message,
        );
      },
      [],
    );
    const setIdentifierInputErrorMessage: GateFormMessageSetter = useCallback(
      (message?) => {
        messageGroupRef.current.setMessage?.call(
          null,
          MESSAGE_KEY.identifierInputError,
          message,
        );
      },
      [],
    );
    const setPassphraseInputErrorMessage: GateFormMessageSetter = useCallback(
      (message?) => {
        messageGroupRef.current.setMessage?.call(
          null,
          MESSAGE_KEY.passphraseInputError,
          message,
        );
      },
      [],
    );

    const identifierInputTestBatch = useMemo(
      () =>
        overwriteIdentifierInputTestBatch?.call(
          null,
          setIdentifierInputErrorMessage,
          inputIdentifierRef.current,
        ) ??
        buildPeacefulStringTestBatch(
          identifierLabel,
          () => {
            setIdentifierInputErrorMessage();
          },
          { getValue: inputIdentifierRef.current.getValue },
          (message) => {
            setIdentifierInputErrorMessage({
              children: message,
              type: 'warning',
            });
          },
        ),
      [
        identifierLabel,
        overwriteIdentifierInputTestBatch,
        setIdentifierInputErrorMessage,
      ],
    );
    const inputTests: InputTestBatches = useMemo(
      () => ({
        [IT_IDS.identifier]: identifierInputTestBatch,
        [IT_IDS.passphrase]: buildPeacefulStringTestBatch(
          passphraseLabel,
          () => {
            setPassphraseInputErrorMessage();
          },
          { getValue: inputPassphraseRef.current.getValue },
          (message) => {
            setPassphraseInputErrorMessage({
              children: message,
              type: 'warning',
            });
          },
        ),
      }),
      [
        identifierInputTestBatch,
        passphraseLabel,
        setPassphraseInputErrorMessage,
      ],
    );
    const submitHandler: ContainedButtonProps['onClick'] = useMemo(
      () =>
        onSubmit ??
        ((...args) => {
          setAccessErrorMessage();
          setIsSubmitting(true);
          onSubmitAppend?.call(
            null,
            inputIdentifierRef.current,
            inputPassphraseRef.current,
            setAccessErrorMessage,
            setIsSubmitting,
            messageGroupRef.current,
            ...args,
          );
        }),
      [onSubmit, onSubmitAppend, setAccessErrorMessage],
    );
    const submitElement = useMemo(
      () =>
        isSubmitting ? (
          <Spinner sx={{ marginTop: 0 }} />
        ) : (
          <FlexBox row sx={{ justifyContent: 'flex-end' }}>
            <ContainedButton
              disabled={isInputIdentifierValid && isInputPassphraseValid}
              onClick={submitHandler}
            >
              {submitLabel}
            </ContainedButton>
          </FlexBox>
        ),
      [
        isInputIdentifierValid,
        isInputPassphraseValid,
        isSubmitting,
        submitHandler,
        submitLabel,
      ],
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

    const testInput = useMemo(
      () => createTestInputFunction(inputTests),
      [inputTests],
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
                    id="credential-identifier-input"
                    inputProps={{
                      onBlur: (event) => {
                        const {
                          target: { value },
                        } = event;

                        const valid = testInput({
                          inputs: { [IT_IDS.identifier]: { value } },
                        });
                        setIsInputIdentifierValid(valid);

                        onIdentifierBlurAppend?.call(null, event);
                      },
                      onFocus: () => {
                        setIdentifierInputErrorMessage();
                      },
                      ...identifierInputProps,
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
                    id="credential-passphrase-input"
                    inputProps={{
                      onBlur: ({ target: { value } }) => {
                        const valid = testInput({
                          inputs: { [IT_IDS.passphrase]: { value } },
                        });
                        setIsInputPassphraseValid(valid);
                      },
                      onFocus: () => {
                        setPassphraseInputErrorMessage();
                      },
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
          'credential-message-group': {
            children: <MessageGroup count={1} ref={messageGroupRef} />,
            sm: 2,
          },
          'credential-submit': submitGrid,
        }}
        spacing={gridSpacing}
        {...restGridProps}
      />
    );
  },
);

GateForm.displayName = 'GateForm';

export default GateForm;
