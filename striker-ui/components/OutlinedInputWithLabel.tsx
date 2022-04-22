import {
  FormControl as MUIFormControl,
  FormControlProps as MUIFormControlProps,
} from '@mui/material';

import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';

type OutlinedInputWithLabelOptionalProps = {
  formControlProps?: Partial<MUIFormControlProps>;
  id?: string;
  inputProps?: Partial<OutlinedInputProps>;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
};

type OutlinedInputWithLabelProps = {
  label: string;
} & OutlinedInputWithLabelOptionalProps;

const OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS: Required<OutlinedInputWithLabelOptionalProps> =
  {
    formControlProps: {},
    id: '',
    inputProps: {},
    inputLabelProps: {},
  };

const OutlinedInputWithLabel = ({
  formControlProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.formControlProps,
  id = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.id,
  inputProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputProps,
  inputLabelProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS.inputLabelProps,
  label,
}: OutlinedInputWithLabelProps): JSX.Element => (
  // eslint-disable-next-line react/jsx-props-no-spreading
  <MUIFormControl {...formControlProps}>
    {/* eslint-disable-next-line react/jsx-props-no-spreading */}
    <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
      {label}
    </OutlinedInputLabel>
    <OutlinedInput
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        fullWidth: formControlProps.fullWidth,
        id,
        label,
        ...inputProps,
      }}
    />
  </MUIFormControl>
);

OutlinedInputWithLabel.defaultProps = OUTLINED_INPUT_WITH_LABEL_DEFAULT_PROPS;

export type { OutlinedInputWithLabelProps };

export default OutlinedInputWithLabel;
