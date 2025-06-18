type PieProgressUnderlineProps =
  import('@mui/material/CircularProgress').CircularProgressProps & {
    offset?: {
      multiplier?: number;
      unit?: string;
    };
  };

type PieProgressProps = {
  error?: boolean;
  slotProps?: {
    box?: import('@mui/material/Box').BoxProps;
    pie?: import('@mui/material/CircularProgress').CircularProgressProps;
    underline?: PieProgressUnderlineProps;
  };
  value?: number;
};
