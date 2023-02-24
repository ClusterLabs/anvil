import { FC } from 'react';
import {
  Box,
  formControlClasses as muiFormControlClasses,
  outlinedInputClasses as muiOutlinedInputClasses,
} from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import SelectWithLabel, { SelectWithLabelProps } from './SelectWithLabel';

type OutlinedLabeledInputWithSelectOptionalProps = {
  inputWithLabelProps?: Partial<OutlinedInputWithLabelProps>;
  messageBoxProps?: Partial<MessageBoxProps>;
  selectWithLabelProps?: Partial<SelectWithLabelProps>;
};

type OutlinedLabeledInputWithSelectProps =
  OutlinedLabeledInputWithSelectOptionalProps & {
    id: string;
    label: string;
    selectItems: SelectItem[];
  };

const OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS: Required<OutlinedLabeledInputWithSelectOptionalProps> =
  {
    inputWithLabelProps: {},
    messageBoxProps: {},
    selectWithLabelProps: {},
  };

const OutlinedLabeledInputWithSelect: FC<
  OutlinedLabeledInputWithSelectProps
> = ({
  id,
  label,
  inputWithLabelProps = OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS.inputWithLabelProps,
  messageBoxProps = OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS.messageBoxProps,
  selectItems,
  selectWithLabelProps = OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS.selectWithLabelProps,
}) => (
  <Box>
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'row',

        '& > :first-child': {
          flexGrow: 1,
        },

        '& > :not(:last-child)': {
          marginRight: '.5em',
        },

        [`&:hover
          .${muiFormControlClasses.root}
          .${muiOutlinedInputClasses.root}
          .${muiOutlinedInputClasses.notchedOutline}`]: {
          borderColor: GREY,
        },
      }}
    >
      <OutlinedInputWithLabel
        {...{
          id,
          label,
          ...inputWithLabelProps,
        }}
      />
      <SelectWithLabel
        {...{
          id: `${id}-nested-select`,
          selectItems,
          ...selectWithLabelProps,
        }}
      />
    </Box>
    <InputMessageBox {...messageBoxProps} />
  </Box>
);

OutlinedLabeledInputWithSelect.defaultProps =
  OUTLINED_LABELED_INPUT_WITH_SELECT_DEFAULT_PROPS;

export type { OutlinedLabeledInputWithSelectProps };

export default OutlinedLabeledInputWithSelect;
