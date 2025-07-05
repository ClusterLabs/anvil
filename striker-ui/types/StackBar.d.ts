type StackBarValue = {
  barProps?: import('@mui/material/LinearProgress').LinearProgressProps;
  colour?: string | Record<number | string, string>;
  value: number;
};

type StackBarOptionalProps = {
  barProps?: import('@mui/material/LinearProgress').LinearProgressProps;
  thin?: boolean;
  underlineProps?: import('@mui/material/Box').BoxProps;
};

type StackBarProps = StackBarOptionalProps & {
  value: StackBarValue | Record<string, StackBarValue>;
};
