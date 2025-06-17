import MuiQuestionMarkIcon from '@mui/icons-material/QuestionMark';
import {
  FormControl as MuiFormControl,
  FormControlProps as MuiFormControlProps,
  IconButton as MuiIconButton,
  IconButtonProps as MuiIconButtonProps,
  iconButtonClasses as muiIconButtonClasses,
  InputAdornment as MuiInputAdornment,
  InputBaseComponentProps as MuiInputBaseComponentProps,
} from '@mui/material';
import { useCallback, useMemo, useState } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalPropsWithDefault = {
  formControlProps?: Partial<MuiFormControlProps>;
  helpMessageBoxProps?: Partial<MessageBoxProps>;
  id?: string;
  inputProps?: Partial<OutlinedInputProps>;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  required?: boolean;
  value?: OutlinedInputProps['value'];
};

type OutlinedInputWithLabelOptionalPropsWithoutDefault = {
  baseInputProps?: MuiInputBaseComponentProps;
  onHelp?: MuiIconButtonProps['onClick'];
  onHelpAppend?: MuiIconButtonProps['onClick'];
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

const OutlinedInputWithLabel: React.FC<OutlinedInputWithLabelProps> = ({
  baseInputProps,
  disableAutofill,
  formControlProps,
  helpMessageBoxProps,
  id = '',
  inputProps: { endAdornment, ...restInputProps } = {},
  inputLabelProps,
  label,
  messageBoxProps,
  name,
  onBlur,
  onChange,
  onFocus,
  onHelp,
  onHelpAppend,
  required,
  type,
  value = '',
}) => {
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
    () => onHelp !== undefined || Boolean(helpMessageBoxProps?.text),
    [helpMessageBoxProps?.text, onHelp],
  );

  const createHelpHandler = useCallback<
    () => MuiIconButtonProps['onClick']
  >(() => {
    let handler: MuiIconButtonProps['onClick'];

    if (onHelp) {
      handler = onHelp;
    } else if (helpMessageBoxProps?.text) {
      handler = (...args) => {
        setIsShowHelp((previous) => !previous);
        onHelpAppend?.call(null, ...args);
      };
    }

    return handler;
  }, [helpMessageBoxProps?.text, onHelp, onHelpAppend]);
  const handleHelp = useMemo(createHelpHandler, [createHelpHandler]);

  return (
    <MuiFormControl fullWidth {...formControlProps}>
      <OutlinedInputLabel htmlFor={id} {...inputLabelProps}>
        {label}
      </OutlinedInputLabel>
      <OutlinedInput
        disableAutofill={disableAutofill}
        endAdornment={
          <MuiInputAdornment
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
              <MuiIconButton onClick={handleHelp} tabIndex={-1}>
                <MuiQuestionMarkIcon />
              </MuiIconButton>
            )}
          </MuiInputAdornment>
        }
        fullWidth={formControlProps?.fullWidth}
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
    </MuiFormControl>
  );
};

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
