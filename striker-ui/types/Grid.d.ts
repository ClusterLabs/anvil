type GridLayout = {
  [id: string]: import('@mui/material/Grid').GridProps | undefined;
};

type GridOptionalProps = {
  calculateItemBreakpoints?: (
    index: number,
    key: string,
  ) => Partial<
    Pick<
      import('@mui/material/Grid').GridProps,
      'xs' | 'sm' | 'md' | 'lg' | 'xl'
    >
  >;
  wrapperBoxProps?: import('@mui/material/Box').BoxProps;
};

type GridProps = import('@mui/material/Grid').GridProps &
  GridOptionalProps & {
    layout: GridLayout;
  };
