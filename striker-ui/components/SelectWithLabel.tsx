import { FC, useCallback, useMemo } from 'react';
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
  selectItems: Array<SelectItem | string>;
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
  selectProps = {},
  isCheckableItems = selectProps?.multiple,
}) => {
  const { sx: selectSx } = selectProps;

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
        readOnly={isReadOnly}
        {...selectProps}
        sx={combinedSx}
      >
        {menuItemElements}
      </Select>
      <InputMessageBox {...messageBoxProps} />
    </MUIFormControl>
  );
};

SelectWithLabel.defaultProps = SELECT_WITH_LABEL_DEFAULT_PROPS;

export type { SelectWithLabelProps };

export default SelectWithLabel;
