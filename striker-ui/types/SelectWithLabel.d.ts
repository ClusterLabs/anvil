type SelectItem<
  Value = string,
  Display extends React.ReactNode = React.ReactNode,
> = {
  displayValue?: Display;
  value: Value;
};

type OperateSelectItemFunction<Value = string> = (value: Value) => boolean;

type SelectWithLabelOptionalProps<Value = string> = {
  checkItem?: OperateSelectItemFunction<Value>;
  disableItem?: OperateSelectItemFunction<Value>;
  formControlProps?: import('@mui/material').FormControlProps;
  hideItem?: OperateSelectItemFunction<Value>;
  isCheckableItems?: boolean;
  isReadOnly?: boolean;
  inputLabelProps?: Partial<
    import('../components/OutlinedInputLabel').OutlinedInputLabelProps
  >;
  label?: string;
  messageBoxProps?: Partial<import('../components/MessageBox').MessageBoxProps>;
  noOptionsText?: React.ReactNode;
  required?: boolean;
  selectProps?: Partial<SelectProps<Value>>;
};

type SelectWithLabelProps<
  Value = string,
  Display extends React.ReactNode = React.ReactNode,
> = SelectWithLabelOptionalProps<Value> &
  Pick<
    SelectProps<Value>,
    'name' | 'onBlur' | 'onChange' | 'onFocus' | 'value'
  > & {
    id: string;
    selectItems: Array<SelectItem<Value, Display> | string>;
  };
