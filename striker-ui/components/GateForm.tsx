import {
  Box as MuiBox,
  BoxProps as MuiBoxProps,
  FormControlProps as MuiFormControlProps,
} from '@mui/material';
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

const INPUT_ROOT_SX: MuiFormControlProps['sx'] = { width: '100%' };

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
      identifierId = INPUT_ID_GATE_ID,
      identifierInputTestBatchBuilder:
        buildIdentifierInputTestBatch = buildPeacefulStringTestBatch,
      identifierLabel,
      identifierOutlinedInputWithLabelProps: {
        formControlProps: identifierFormControlProps = {},
        inputProps: identifierInputProps,
        ...restIdentifierOutlinedInputWithLabelProps
      } = {},
      onIdentifierBlurAppend,
      onSubmit,
      onSubmitAppend,
      passphraseId = INPUT_ID_GATE_PASSPHRASE,
      passphraseLabel,
      passphraseOutlinedInputWithLabelProps: {
        formControlProps: passphraseFormControlProps = {},
        inputProps: passphraseInputProps,
        ...restPassphraseOutlinedInputWithLabelProps
      } = {},
      submitLabel,
      // Props that depend on others.
      allowSubmit: isAllowSubmit = isFormContainer,
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
      [identifierId, passphraseId],
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

          const { target } = event;
          const { elements } = target as HTMLFormElement;

          const { value: identifierValue } = elements.namedItem(
            identifierId,
          ) as HTMLInputElement;
          const { value: passphraseValue } = elements.namedItem(
            passphraseId,
          ) as HTMLInputElement;

          onSubmitAppend?.call(
            null,
            identifierValue,
            passphraseValue,
            (message?) => {
              setMessage(MSG_ID_GATE_ACCESS, message);
            },
            setIsSubmitting,
            ...args,
          );
        }),
      [
        identifierId,
        onSubmit,
        onSubmitAppend,
        passphraseId,
        setIsSubmitting,
        setMessage,
      ],
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

      if (isAllowSubmit) {
        result['gate-cell-message-group'] = {
          children: (
            <MessageGroup
              count={1}
              defaultMessageType="warning"
              ref={messageGroupRef}
            />
          ),
          sm: 2,
        };
        result['gate-cell-submit'] = { children: submitElement, sm: 2 };
      }

      return result;
    }, [isAllowSubmit, submitElement]);

    const containerProps = useMemo(() => {
      const result: MuiBoxProps = {};

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
      <MuiBox {...containerProps}>
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
                      id={identifierId}
                      inputProps={identifierInputProps}
                      label={identifierLabel}
                      {...restIdentifierOutlinedInputWithLabelProps}
                    />
                  }
                  inputTestBatch={buildIdentifierInputTestBatch(
                    identifierLabel,
                    () => {
                      setMessage(identifierId);
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(identifierId),
                    },
                    (message) => {
                      setMessage(identifierId, { children: message });
                    },
                  )}
                  onBlurAppend={(...args) => {
                    onIdentifierBlurAppend?.call(null, ...args);
                  }}
                  onFirstRender={buildInputFirstRenderFunction(identifierId)}
                  onUnmount={buildInputUnmountFunction(identifierId)}
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
                      id={passphraseId}
                      inputProps={passphraseInputProps}
                      label={passphraseLabel}
                      type={INPUT_TYPES.password}
                      {...restPassphraseOutlinedInputWithLabelProps}
                    />
                  }
                  inputTestBatch={buildPeacefulStringTestBatch(
                    passphraseLabel,
                    () => {
                      setMessage(passphraseId);
                    },
                    {
                      onFinishBatch:
                        buildFinishInputTestBatchFunction(passphraseId),
                    },
                    (message) => {
                      setMessage(passphraseId, {
                        children: message,
                      });
                    },
                  )}
                  onFirstRender={buildInputFirstRenderFunction(passphraseId)}
                  onUnmount={buildInputUnmountFunction(passphraseId)}
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
      </MuiBox>
    );
  },
);

GateForm.displayName = 'GateForm';

export { INPUT_ID_GATE_ID, INPUT_ID_GATE_PASSPHRASE };

export default GateForm;
