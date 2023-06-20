type SelectChangeEventHandler = Exclude<
  import('@mui/material').SelectProps['onChange'],
  undefined
>;

type SelectOptionalProps = {
  onClearIndicatorClick?: import('@mui/material').IconButtonProps['onClick'];
};

type SelectProps = import('@mui/material').SelectProps & SelectOptionalProps;
