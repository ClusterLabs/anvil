type SelectChangeEventHandler = Exclude<
  import('@mui/material/Select').SelectProps['onChange'],
  undefined
>;

type SelectOptionalProps = {
  onClearIndicatorClick?: import('@mui/material/IconButton').IconButtonProps['onClick'];
};

type SelectProps<Value = string> =
  import('@mui/material/Select').SelectProps<Value> & SelectOptionalProps;
