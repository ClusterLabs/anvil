type SelectChangeEventHandler = Exclude<
  import('@mui/material').SelectProps['onChange'],
  undefined
>;

type SelectOptionalProps = {
  onClearIndicatorClick?: import('@mui/material').IconButtonProps['onClick'];
};

type SelectProps<Value = string> = import('@mui/material').SelectProps<Value> &
  SelectOptionalProps;
