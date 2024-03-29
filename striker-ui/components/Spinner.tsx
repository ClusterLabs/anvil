import { FC } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  CircularProgress as MUICircularProgress,
  circularProgressClasses as muiCircularProgressClasses,
  CircularProgressProps as MUICircularProgressProps,
} from '@mui/material';

import { TEXT } from '../lib/consts/DEFAULT_THEME';

type SpinnerOptionalProps = {
  progressProps?: MUICircularProgressProps;
};

type SpinnerProps = MUIBoxProps & SpinnerOptionalProps;

const SPINNER_DEFAULT_PROPS: Required<SpinnerOptionalProps> = {
  progressProps: {},
};

const Spinner: FC<SpinnerProps> = (spinnerProps): JSX.Element => {
  const {
    mt = '3em',
    progressProps = SPINNER_DEFAULT_PROPS.progressProps,
    sx,
    ...spinnerRestProps
  } = spinnerProps;

  return (
    <MUIBox
      {...{
        ...spinnerRestProps,

        sx: {
          alignItems: 'center',
          display: 'flex',
          justifyContent: 'center',
          marginTop: mt,

          [`& .${muiCircularProgressClasses.root}`]: {
            color: TEXT,
          },

          ...sx,
        },
      }}
    >
      <MUICircularProgress
        {...{ ...progressProps, variant: 'indeterminate' }}
      />
    </MUIBox>
  );
};

Spinner.defaultProps = SPINNER_DEFAULT_PROPS;

export default Spinner;
