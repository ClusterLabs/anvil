type StackBarValue = {
  colour?: string | Record<number, string>;
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
