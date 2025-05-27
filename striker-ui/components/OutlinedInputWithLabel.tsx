import { QuestionMark as MUIQuestionMarkIcon } from '@mui/icons-material';
import {
  FormControl as MUIFormControl,
  FormControlProps as MUIFormControlProps,
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  iconButtonClasses as muiIconButtonClasses,
  InputAdornment as MUIInputAdornment,
  InputBaseComponentProps as MUIInputBaseComponentProps,
} from '@mui/material';
import { FC, useCallback, useMemo, useState } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalPropsWithDefault = {
  formControlProps?: Partial<MUIFormControlProps>;
  helpMessageBoxProps?: Partial<MessageBoxProps>;
  id?: string;
  inputProps?: Partial<OutlinedInputProps>;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  required?: boolean;
  value?: OutlinedInputProps['value'];
};

type OutlinedInputWithLabelOptionalPropsWithoutDefault = {
  baseInputProps?: MUIInputBaseComponentProps;
  onHelp?: MUIIconButtonProps['onClick'];
  onHelpAppend?: MUIIconButtonProps['onClick'];
  type?: string;
};

type OutlinedInputWithLabelOptionalProps =
  OutlinedInputWithLabelOptionalPropsWithDefault &
    OutlinedInputWithLabelOptionalPropsWithoutDefault;

type OutlinedInputWithLabelProps = Pick<
  OutlinedInputProps,
  'disableAutofill' | 'name' | 'onBlur' | 'onChange' | 'onFocus'
> &
  OutlinedInputWithLabelOptionalProps & {
    label: string;
  };

const OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS: Required<OutlinedInputWithLabelOptionalPropsWithDefault> &
  OutlinedInputWithLabelOptionalPropsWithoutDefault = {
  baseInputProps: undefined,
  formControlProps: {},
  helpMessageBoxProps: {},
  id: '',
  inputProps: {},
  inputLabelProps: {},
  messageBoxProps: {},
  onHelp: undefined,
  onHelpAppend: undefined,
  required: false,
  type: undefined,
  value: '',
};

const OutlinedInputWithLabel: FC<OutlinedInputWithLabelProps> = ({
  baseInputProps,
  disableAutofill,
  formControlProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.formControlProps,
  helpMessageBoxProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.helpMessageBoxProps,
  id = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.id,
  inputProps: {
    endAdornment,
    ...restInputProps
  } = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputProps,
  inputLabelProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputLabelProps,
  label,
  messageBoxProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.messageBoxProps,
  name,
  onBlur,
  onChange,
  onFocus,
  onHelp,
  onHelpAppend,
  required = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.required,
  type,
  value = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.value,
}) => {
  const { text: helpText = '' } = helpMessageBoxProps;

  const [isShowHelp, setIsShowHelp] = useState<boolean>(false);

  const helpElement = useMemo(
    () =>
      isShowHelp && (
        <InputMessageBox
          onClose={() => {
            setIsShowHelp(false);
          }}
          {...helpMessageBoxProps}
        />
      ),
    [helpMessageBoxProps, isShowHelp],
  );
  const isShowHelpButton: boolean = useMemo(
    () => onHelp !== undefined || helpText.length > 0,
    [helpText, onHelp],
  );

  const createHelpHandler = useCallback<
    () => MUIIconButtonProps['onClick']
  >(() => {
    let handler: MUIIconButtonProps['onClick'];

    if (onHelp) {
      handler = onHelp;
    } else if (helpText.length > 0) {
      handler = (...args) => {
        setIsShowHelp((previous) => !previous);
        onHelpAppend?.call(null, ...args);
      };
    }

    return handler;
  }, [helpText, onHelp, onHelpAppend]);
  const handleHelp = useMemo(createHelpHandler, [createHelpHandler]);

  return (
    <MUIFormControl fullWidth {...formControlProps}>
      <OutlinedInputLabel htmlFor={id} {...inputLabelProps}>
        {label}
      </OutlinedInputLabel>
      <OutlinedInput
        disableAutofill={disableAutofill}
        endAdornment={
          <MUIInputAdornment
            position="end"
            sx={{
              display: 'flex',
              flexDirection: 'row',

              [`& > .${muiIconButtonClasses.root}`]: {
                color: GREY,
                padding: '.2em',
              },

              [`& > :not(:first-child, .${muiIconButtonClasses.root})`]: {
                marginLeft: '.3em',
              },
            }}
          >
            {endAdornment}
            {isShowHelpButton && (
              <MUIIconButton onClick={handleHelp} tabIndex={-1}>
                <MUIQuestionMarkIcon />
              </MUIIconButton>
            )}
          </MUIInputAdornment>
        }
        fullWidth={formControlProps.fullWidth}
        id={id}
        inputProps={baseInputProps}
        label={label}
        name={name}
        onBlur={onBlur}
        onChange={onChange}
        onFocus={onFocus}
        required={required}
        type={type}
        value={value}
        {...restInputProps}
      />
      {helpElement}
      <InputMessageBox {...messageBoxProps} />
    </MUIFormControl>
  );
};

OutlinedInputWithLabel.defaultProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS;

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
