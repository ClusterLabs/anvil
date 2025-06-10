import {
  Box as MuiBox,
  formControlClasses as muiFormControlClasses,
  outlinedInputClasses as muiOutlinedInputClasses,
} from '@mui/material';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInputWithLabel, {
  OutlinedInputWithLabelProps,
} from './OutlinedInputWithLabel';
import SelectWithLabel from './SelectWithLabel';

type OutlinedLabeledInputWithSelectOptionalProps = Pick<
  OutlinedInputWithLabelProps,
  'onChange' | 'value'
> & {
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

const OutlinedLabeledInputWithSelect: React.FC<
  OutlinedLabeledInputWithSelectProps
> = ({
  id,
  label,
  inputWithLabelProps,
  messageBoxProps,
  onChange,
  selectItems,
  selectWithLabelProps,
  value,
}) => (
  <MuiBox>
    <MuiBox
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
        id={id}
        label={label}
        onChange={onChange}
        value={value}
        {...inputWithLabelProps}
      />
      <SelectWithLabel
        formControlProps={{ fullWidth: false, sx: { minWidth: 'min-content' } }}
        id={`${id}-nested-select`}
        selectItems={selectItems}
        {...selectWithLabelProps}
      />
    </MuiBox>
    <InputMessageBox {...messageBoxProps} />
  </MuiBox>
);

export type { OutlinedLabeledInputWithSelectProps };

export default OutlinedLabeledInputWithSelect;
