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

const SelectWithLabel = <
  Value = string,
  Display extends React.ReactNode = React.ReactNode,
>(
  ...[props]: Parameters<FC<SelectWithLabelProps<Value, Display>>>
): ReturnType<FC<SelectWithLabelProps<Value, Display>>> => {
  const {
    id,
    label,
    selectItems,
    checkItem,
    disableItem,
    formControlProps,
    hideItem,
    inputLabelProps = {},
    isReadOnly = false,
    messageBoxProps = {},
    name,
    onBlur,
    onChange,
    onFocus,
    required: isRequired,
    selectProps: {
      multiple: selectMultiple,
      sx: selectSx,
      ...restSelectProps
    } = {},
    value: selectValue,
    // Props with initial value that depend on others.
    isCheckableItems = selectMultiple,
  } = props;

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

  const selectId = useMemo(() => `${id}-select-element`, [id]);

  const inputElement = useMemo(
    () => <OutlinedInput id={id} label={label} />,
    [id, label],
  );
  const labelElement = useMemo(
    () =>
      label && (
        <OutlinedInputLabel
          htmlFor={selectId}
          isNotifyRequired={isRequired}
          {...inputLabelProps}
        >
          {label}
        </OutlinedInputLabel>
      ),
    [inputLabelProps, isRequired, label, selectId],
  );
  const menuItemElements = useMemo(
    () =>
      selectItems.map((item) => {
        const { value, displayValue }: SelectItem<Value, Display> =
          typeof item === 'object'
            ? item
            : { displayValue: item as Display, value: item as Value };

        return createMenuItem(value, displayValue);
      }),
    [createMenuItem, selectItems],
  );

  return (
    <MUIFormControl fullWidth {...formControlProps}>
      {labelElement}
      <Select<Value>
        id={selectId}
        input={inputElement}
        multiple={selectMultiple}
        name={name}
        onBlur={onBlur}
        onChange={onChange}
        onFocus={onFocus}
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
