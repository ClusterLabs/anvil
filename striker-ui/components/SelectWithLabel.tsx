import {
  Checkbox as MuiCheckbox,
  FormControl as MuiFormControl,
  menuClasses as muiMenuClasses,
  selectClasses as muiSelectClasses,
} from '@mui/material';
import { merge } from 'lodash';
import { FC, useCallback, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

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
    noOptionsText = 'No options',
    onBlur,
    onChange,
    onFocus,
    required,
    selectProps: {
      MenuProps: selectMenuProps,
      multiple: selectMultiple,
      sx: selectSx,
      ...restSelectProps
    } = {},
    value: selectValue,
    // Props with initial value that depend on others.
    isCheckableItems = selectMultiple,
  } = props;

  const mergedSx = useMemo(
    () =>
      isReadOnly
        ? merge(
            {
              [`& .${muiSelectClasses.icon}`]: {
                visibility: 'hidden',
              },
            },
            selectSx,
          )
        : selectSx,
    [isReadOnly, selectSx],
  );

  const createCheckbox = useCallback(
    (value) =>
      isCheckableItems && (
        <MuiCheckbox checked={checkItem?.call(null, value)} />
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
    () => <OutlinedInput id={id} label={label} required={required} />,
    [id, label, required],
  );
  const labelElement = useMemo(
    () =>
      label && (
        <OutlinedInputLabel htmlFor={selectId} {...inputLabelProps}>
          {label}
        </OutlinedInputLabel>
      ),
    [inputLabelProps, label, selectId],
  );
  const menuItemElements = useMemo(() => {
    if (!selectItems.length) {
      return <MenuItem disabled>{noOptionsText}</MenuItem>;
    }

    return selectItems.map((item) => {
      /**
       * Cases:
       * 1. item is string
       * 2. item is SelectItem with only value
       * 3. item is SelectItem with both value, and displayValue
       */

      if (typeof item === 'string') return createMenuItem(item, item);

      const {
        value,
        displayValue = String(value),
      }: SelectItem<Value, Display> = item;

      return createMenuItem(value, displayValue);
    });
  }, [createMenuItem, noOptionsText, selectItems]);

  const mergedSelectMenuProps = useMemo(
    () =>
      merge(
        {
          sx: {
            [`& .${muiMenuClasses.paper}`]: {
              backgroundColor: GREY,
            },
          },
        },
        selectMenuProps,
      ),
    [selectMenuProps],
  );

  return (
    <MuiFormControl fullWidth {...formControlProps}>
      {labelElement}
      <Select<Value>
        id={selectId}
        input={inputElement}
        MenuProps={mergedSelectMenuProps}
        multiple={selectMultiple}
        name={name}
        onBlur={onBlur}
        onChange={onChange}
        onFocus={onFocus}
        readOnly={isReadOnly}
        value={selectValue}
        {...restSelectProps}
        sx={mergedSx}
      >
        {menuItemElements}
      </Select>
      <InputMessageBox {...messageBoxProps} />
    </MuiFormControl>
  );
};

export default SelectWithLabel;
