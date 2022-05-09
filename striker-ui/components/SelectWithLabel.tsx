import { FC, ReactNode } from 'react';
import {
  Checkbox as MUICheckbox,
  FormControl as MUIFormControl,
} from '@mui/material';

import InputMessageBox from './InputMessageBox';
import MenuItem from './MenuItem';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';
import Select, { SelectProps } from './Select';

type SelectItem<
  ValueType = string,
  DisplayValueType = ValueType | ReactNode,
> = {
  displayValue?: DisplayValueType;
  value: ValueType;
};

type SelectWithLabelOptionalProps = {
  checkItem?: ((value: string) => boolean) | null;
  disableItem?: ((value: string) => boolean) | null;
  hideItem?: ((value: string) => boolean) | null;
  isCheckableItems?: boolean;
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
  messageBoxProps,
  selectProps,
  isCheckableItems = selectProps?.multiple,
}) => (
  <MUIFormControl>
    {label && (
      // eslint-disable-next-line react/jsx-props-no-spreading
      <OutlinedInputLabel {...{ htmlFor: id, ...inputLabelProps }}>
        {label}
      </OutlinedInputLabel>
    )}
    <Select
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        id,
        input: <OutlinedInput {...{ label }} />,
        ...selectProps,
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
    {/* eslint-disable-next-line react/jsx-props-no-spreading */}
    <InputMessageBox {...messageBoxProps} />
  </MUIFormControl>
);

SelectWithLabel.defaultProps = SELECT_WITH_LABEL_DEFAULT_PROPS;

export type { SelectItem, SelectWithLabelProps };

export default SelectWithLabel;
