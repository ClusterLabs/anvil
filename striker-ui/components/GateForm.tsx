import { Box, BoxProps, SxProps, Theme } from '@mui/material';
import {
  forwardRef,
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
import { buildPeacefulStringTestBatch } from '../lib/test_input';
import useFormUtils from '../hooks/useFormUtils';

const INPUT_ROOT_SX: SxProps<Theme> = { width: '100%' };

const INPUT_ID_PREFIX_GATE = 'gate-input';

const INPUT_ID_GATE_ID = `${INPUT_ID_PREFIX_GATE}-credential-id`;
const INPUT_ID_GATE_PASSPHRASE = `${INPUT_ID_PREFIX_GATE}-credential-passphrase`;

const MSG_ID_GATE_ACCESS = 'access';

const GateForm = forwardRef<GateFormForwardedRefContent, GateFormProps>(
  (
    {
      formContainer: isFormContainer = true,
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
      identifierInputTestBatchBuilder:
        buildIdentifierInputTestBatch = buildPeacefulStringTestBatch,
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

    const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

    const formUtils = useFormUtils(
      [INPUT_ID_GATE_ID, INPUT_ID_GATE_PASSPHRASE],
      messageGroupRef,
    );
    const {
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      buildInputUnmountFunction,
      isFormInvalid,
      setMessage,
    } = formUtils;

    const submitHandler: DivFormEventHandler = useMemo(
      () =>
        onSubmit ??
        ((...args) => {
          const { 0: event } = args;

          event.preventDefault();

          setMessage(MSG_ID_GATE_ACCESS);
          setIsSubmitting(true);
          onSubmitAppend?.call(
            null,
            inputIdentifierRef.current,
            inputPassphraseRef.current,
            (message?) => {
              setMessage(MSG_ID_GATE_ACCESS, message);
            },
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
          <Spinner mt={0} />
        ) : (
          <FlexBox row sx={{ justifyContent: 'flex-end' }}>
            <ContainedButton disabled={isFormInvalid} type="submit">
              {submitLabel}
            </ContainedButton>
          </FlexBox>
        ),
      [isFormInvalid, isSubmitting, submitLabel],
    );

    const submitAreaGridLayout = useMemo(() => {
      const result: GridLayout = {};

      if (isFormContainer) {
        result['gate-cell-message-group'] = {
          children: <MessageGroup count={1} ref={messageGroupRef} />,
          sm: 2,
        };
        result['gate-cell-submit'] = { children: submitElement, sm: 2 };
      }

      return result;
    }, [isFormContainer, submitElement]);

    const containerProps = useMemo(() => {
      const result: BoxProps = {};

      if (isFormContainer) {
        result.component = 'form';
        result.onSubmit = submitHandler;
      }

      return result;
    }, [isFormContainer, submitHandler]);

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
      <Box {...containerProps}>
        <Grid
          columns={gridColumns}
          layout={{
            'gate-input-cell-credential-id': {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      formControlProps={{
                        ...restIdentifierFormControlProps,
                        sx: { ...INPUT_ROOT_SX, ...identifierSx },
                      }}
                      id={INPUT_ID_GATE_ID}
                      inputProps={identifierInputProps}
                      label={identifierLabel}
                      {...restIdentifierOutlinedInputWithLabelProps}
                    />
                  }
                  inputTestBatch={buildIdentifierInputTestBatch(
                    identifierLabel,
                    () => {
                      setMessage(INPUT_ID_GATE_ID);
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(INPUT_ID_GATE_ID),
                    },
                    (message) => {
                      setMessage(INPUT_ID_GATE_ID, { children: message });
                    },
                  )}
                  onBlurAppend={(...args) => {
                    onIdentifierBlurAppend?.call(null, ...args);
                  }}
                  onFirstRender={buildInputFirstRenderFunction(
                    INPUT_ID_GATE_ID,
                  )}
                  onUnmount={buildInputUnmountFunction(INPUT_ID_GATE_ID)}
                  ref={inputIdentifierRef}
                  required
                />
              ),
            },
            'gate-input-cell-credential-passphrase': {
              children: (
                <InputWithRef
                  input={
                    <OutlinedInputWithLabel
                      formControlProps={{
                        ...restPassphraseFormControlProps,
                        sx: { ...INPUT_ROOT_SX, ...passphraseSx },
                      }}
                      id={INPUT_ID_GATE_PASSPHRASE}
                      inputProps={passphraseInputProps}
                      label={passphraseLabel}
                      type={INPUT_TYPES.password}
                      {...restPassphraseOutlinedInputWithLabelProps}
                    />
                  }
                  inputTestBatch={buildPeacefulStringTestBatch(
                    passphraseLabel,
                    () => {
                      setMessage(INPUT_ID_GATE_PASSPHRASE);
                    },
                    {
                      onFinishBatch: buildFinishInputTestBatchFunction(
                        INPUT_ID_GATE_PASSPHRASE,
                      ),
                    },
                    (message) => {
                      setMessage(INPUT_ID_GATE_PASSPHRASE, {
                        children: message,
                      });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(
                    INPUT_ID_GATE_PASSPHRASE,
                  )}
                  onUnmount={buildInputUnmountFunction(
                    INPUT_ID_GATE_PASSPHRASE,
                  )}
                  ref={inputPassphraseRef}
                  required
                />
              ),
            },
            ...submitAreaGridLayout,
          }}
          spacing={gridSpacing}
          {...restGridProps}
        />
      </Box>
    );
  },
);

GateForm.displayName = 'GateForm';

export { INPUT_ID_GATE_ID, INPUT_ID_GATE_PASSPHRASE };

export default GateForm;
