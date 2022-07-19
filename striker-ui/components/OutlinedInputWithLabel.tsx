import {
  FormControl as MUIFormControl,
  FormControlProps as MUIFormControlProps,
} from '@mui/material';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalProps = {
  formControlProps?: Partial<MUIFormControlProps>;
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
  id: '',
  inputProps: {},
  inputLabelProps: {},
  messageBoxProps: {},
  onChange: undefined,
  value: '',
};

const OutlinedInputWithLabel = ({
  formControlProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.formControlProps,
  id = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.id,
  inputProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputProps,
  inputLabelProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputLabelProps,
  label,
  messageBoxProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.messageBoxProps,
  onChange,
  value = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.value,
}: OutlinedInputWithLabelProps): JSX.Element => (
  <MUIFormControl {...formControlProps}>
    <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
      {label}
    </OutlinedInputLabel>
    <OutlinedInput
      {...{
        fullWidth: formControlProps.fullWidth,
        id,
        label,
        onChange,
        value,
        ...inputProps,
      }}
    />
    <InputMessageBox {...messageBoxProps} />
  </MUIFormControl>
);

OutlinedInputWithLabel.defaultProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS;

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
