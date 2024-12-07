type PieProgressUnderlineProps =
  import('@mui/material').CircularProgressProps & {
    offset?: {
      multiplier?: number;
      unit?: string;
    };
  };

type PieProgressProps = {
  slotProps?: {
    box?: import('@mui/material').BoxProps;
    pie?: import('@mui/material').CircularProgressProps;
    underline?: PieProgressUnderlineProps;
  };
  value?: number;
};
