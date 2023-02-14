import { FC } from 'react';
import {
  Checkbox as MUICheckbox,
  FormControl as MUIFormControl,
  selectClasses as muiSelectClasses,
} from '@mui/material';

import InputMessageBox from './InputMessageBox';
import MenuItem from './MenuItem';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';
import Select, { SelectProps } from './Select';

type SelectWithLabelOptionalProps = {
  checkItem?: ((value: string) => boolean) | null;
  disableItem?: ((value: string) => boolean) | null;
  hideItem?: ((value: string) => boolean) | null;
  isCheckableItems?: boolean;
  isReadOnly?: boolean;
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  label?: string | null;
  messageBoxProps?: Partial<MessageBoxProps>;
  selectProps?: Partial<SelectProps>;
};

type SelectWithLabelProps = SelectWithLabelOptionalProps & {
  id: string;
  selectItems: SelectItem[];
};

const SELECT_WITH_LABEL_DEFAULT_PROPS: Required<SelectWithLabelOptionalProps> =
  {
    checkItem: null,
    disableItem: null,
    hideItem: null,
    isReadOnly: false,
    isCheckableItems: false,
    inputLabelProps: {},
    label: null,
    messageBoxProps: {},
    selectProps: {},
  };

const SelectWithLabel: FC<SelectWithLabelProps> = ({
  id,
  label,
  selectItems,
  checkItem,
  disableItem,
  hideItem,
  inputLabelProps,
  isReadOnly,
  messageBoxProps,
  selectProps,
  isCheckableItems = selectProps?.multiple,
}) => (
  <MUIFormControl>
    {label && (
      <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
        {label}
      </OutlinedInputLabel>
    )}
    <Select
      {...{
        id,
        input: <OutlinedInput {...{ label }} />,
        readOnly: isReadOnly,
        ...selectProps,
        sx: isReadOnly
          ? {
              [`& .${muiSelectClasses.icon}`]: {
                visibility: 'hidden',
              },

              ...selectProps?.sx,
            }
          : selectProps?.sx,
      }}
    >
      {selectItems.map(({ value, displayValue = value }) => (
        <MenuItem
          disabled={disableItem?.call(null, value)}
          key={`${id}-${value}`}
          sx={{
            display: hideItem?.call(null, value) ? 'none' : undefined,
          }}
          value={value}
        >
          {isCheckableItems && (
            <MUICheckbox checked={checkItem?.call(null, value)} />
          )}
          {displayValue}
        </MenuItem>
      ))}
    </Select>
    <InputMessageBox {...messageBoxProps} />
  </MUIFormControl>
);

SelectWithLabel.defaultProps = SELECT_WITH_LABEL_DEFAULT_PROPS;

export type { SelectWithLabelProps };

export default SelectWithLabel;
