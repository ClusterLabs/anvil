import { FC, useState } from 'react';
import {
  FormControl as MUIFormControl,
  FormControlProps as MUIFormControlProps,
  IconButton as MUIIconButton,
  InputAdornment as MUIInputAdornment,
} from '@mui/material';
import { QuestionMark as MUIQuestionMarkIcon } from '@mui/icons-material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalProps = {
  formControlProps?: Partial<MUIFormControlProps>;
  helpMessageBoxProps?: Partial<MessageBoxProps>;
  id?: string;
  inputProps?: Partial<OutlinedInputProps>;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  onChange?: OutlinedInputProps['onChange'];
  value?: OutlinedInputProps['value'];
};

type OutlinedInputWithLabelProps = {
  label: string;
} & OutlinedInputWithLabelOptionalProps;

const OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS: Required<
  Omit<OutlinedInputWithLabelOptionalProps, 'onChange'>
> &
  Pick<OutlinedInputWithLabelOptionalProps, 'onChange'> = {
  formControlProps: {},
  helpMessageBoxProps: {},
  id: '',
  inputProps: {},
  inputLabelProps: {},
  messageBoxProps: {},
  onChange: undefined,
  value: '',
};

const OutlinedInputWithLabel: FC<OutlinedInputWithLabelProps> = ({
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
  onChange,
  value = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.value,
}) => {
  const { text: helpText } = helpMessageBoxProps;

  const [isShowHelp, setIsShowHelp] = useState<boolean>(false);

  return (
    <MUIFormControl {...formControlProps}>
      <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
        {label}
      </OutlinedInputLabel>
      <OutlinedInput
        {...{
          endAdornment: (
            <MUIInputAdornment
              position="end"
              sx={{
                display: 'flex',
                flexDirection: 'row',

                '& > :not(:first-child)': {
                  marginLeft: '.3em',
                },
              }}
            >
              {endAdornment}
              {helpText && (
                <MUIIconButton
                  onClick={() => {
                    setIsShowHelp(true);
                  }}
                  sx={{
                    color: GREY,
                    padding: '.1em',
                  }}
                >
                  <MUIQuestionMarkIcon />
                </MUIIconButton>
              )}
            </MUIInputAdornment>
          ),
          fullWidth: formControlProps.fullWidth,
          id,
          label,
          onChange,
          value,
          ...restInputProps,
        }}
      />
      {isShowHelp && (
        <InputMessageBox
          {...{
            onClose: () => {
              setIsShowHelp(false);
            },

            ...helpMessageBoxProps,
          }}
        />
      )}
      <InputMessageBox {...messageBoxProps} />
    </MUIFormControl>
  );
};

OutlinedInputWithLabel.defaultProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS;

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
