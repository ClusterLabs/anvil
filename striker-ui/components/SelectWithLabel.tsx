import {
  Checkbox as MUICheckbox,
  FormControl as MUIFormControl,
  selectClasses as muiSelectClasses,
} from '@mui/material';
import { FC, useCallback, useMemo } from 'react';

import InputMessageBox from './InputMessageBox';
import MenuItem from './MenuItem';
import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel from './OutlinedInputLabel';
import Select from './Select';

const SelectWithLabel: FC<SelectWithLabelProps> = ({
  id,
  label,
  selectItems,
  checkItem,
  disableItem,
  hideItem,
  inputLabelProps = {},
  isReadOnly = false,
  messageBoxProps = {},
  name,
  onChange,
  selectProps: {
    multiple: selectMultiple,
    sx: selectSx,
    ...restSelectProps
  } = {},
  value: selectValue,
  // Props with initial value that depend on others.
  isCheckableItems = selectMultiple,
}) => {
  const combinedSx = useMemo(
    () =>
      isReadOnly
        ? {
            [`& .${muiSelectClasses.icon}`]: {
              visibility: 'hidden',
            },

            ...selectSx,
          }
        : selectSx,
    [isReadOnly, selectSx],
  );

  const createCheckbox = useCallback(
    (value) =>
      isCheckableItems && (
        <MUICheckbox checked={checkItem?.call(null, value)} />
      ),
    [checkItem, isCheckableItems],
  );
  const createMenuItem = useCallback(
    (value, displayValue) => (
      <MenuItem
        disabled={disableItem?.call(null, value)}
        key={`${id}-${value}`}
        sx={{
          display: hideItem?.call(null, value) ? 'none' : undefined,
        }}
        value={value}
      >
        {createCheckbox(value)}
        {displayValue}
      </MenuItem>
    ),
    [createCheckbox, disableItem, hideItem, id],
  );

  const inputElement = useMemo(() => <OutlinedInput label={label} />, [label]);
  const labelElement = useMemo(
    () =>
      label && (
        <OutlinedInputLabel htmlFor={id} {...inputLabelProps}>
          {label}
        </OutlinedInputLabel>
      ),
    [id, inputLabelProps, label],
  );
  const menuItemElements = useMemo(
    () =>
      selectItems.map((item) => {
        const { value, displayValue = value }: SelectItem =
          typeof item === 'string' ? { value: item } : item;

        return createMenuItem(value, displayValue);
      }),
    [createMenuItem, selectItems],
  );

  return (
    <MUIFormControl>
      {labelElement}
      <Select
        id={id}
        input={inputElement}
        multiple={selectMultiple}
        name={name}
        onChange={onChange}
        readOnly={isReadOnly}
        value={selectValue}
        {...restSelectProps}
        sx={combinedSx}
      >
        {menuItemElements}
      </Select>
      <InputMessageBox {...messageBoxProps} />
    </MUIFormControl>
  );
};

export default SelectWithLabel;
