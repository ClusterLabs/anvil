type GridLayout = {
  [id: string]: import('@mui/material').GridProps;
};

type GridOptionalProps = {
  calculateItemBreakpoints?: (
    index: number,
    key: string,
  ) => Partial<
    Pick<import('@mui/material').GridProps, 'xs' | 'sm' | 'md' | 'lg' | 'xl'>
  >;
  wrapperBoxProps?: import('@mui/material').BoxProps;
};

type GridProps = import('@mui/material').GridProps &
  GridOptionalProps & {
    layout: GridLayout;
  };
