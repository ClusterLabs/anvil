type StackBarValue = {
  barProps?: import('@mui/material').LinearProgressProps;
  colour?: string | Record<number | string, string>;
  value: number;
};

type StackBarOptionalProps = {
  barProps?: import('@mui/material').LinearProgressProps;
  thin?: boolean;
  underlineProps?: import('@mui/material').BoxProps;
};

type StackBarProps = StackBarOptionalProps & {
  value: StackBarValue | Record<string, StackBarValue>;
};
