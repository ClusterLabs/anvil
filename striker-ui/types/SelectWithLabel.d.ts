type SelectItem<
  ValueType = string,
  DisplayValueType = ValueType | import('react').ReactNode,
> = {
  displayValue?: DisplayValueType;
  value: ValueType;
};

type OperateSelectItemFunction = (value: string) => boolean;

type SelectWithLabelOptionalProps = {
  checkItem?: OperateSelectItemFunction;
  disableItem?: OperateSelectItemFunction;
  formControlProps?: import('@mui/material').FormControlProps;
  hideItem?: OperateSelectItemFunction;
  isCheckableItems?: boolean;
  isReadOnly?: boolean;
  inputLabelProps?: Partial<
    import('../components/OutlinedInputLabel').OutlinedInputLabelProps
  >;
  label?: string;
  messageBoxProps?: Partial<import('../components/MessageBox').MessageBoxProps>;
  selectProps?: Partial<SelectProps>;
};

type SelectWithLabelProps = SelectWithLabelOptionalProps &
  Pick<SelectProps, 'name' | 'onChange' | 'value'> & {
    id: string;
    selectItems: Array<SelectItem | string>;
  };
