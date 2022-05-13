import { FC } from 'react';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  CircularProgress as MUICircularProgress,
  circularProgressClasses as muiCircularProgressClasses,
} from '@mui/material';

import { TEXT } from '../lib/consts/DEFAULT_THEME';

type SpinnerProps = MUIBoxProps;

const Spinner: FC<SpinnerProps> = (spinnerProps): JSX.Element => {
  const { sx, ...spinnerRestProps } = spinnerProps;

  return (
    <MUIBox
      {...{
        ...spinnerRestProps,
        sx: {
          alignItems: 'center',
          display: 'flex',
          justifyContent: 'center',
          marginTop: '3em',

          [`& .${muiCircularProgressClasses.root}`]: {
            color: TEXT,
          },

          ...sx,
        },
      }}
    >
      <MUICircularProgress variant="indeterminate" />
    </MUIBox>
  );
};

export default Spinner;
