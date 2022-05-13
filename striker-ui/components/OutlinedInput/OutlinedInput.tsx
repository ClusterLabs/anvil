import { FC } from 'react';
import {
  OutlinedInput as MUIOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
} from '@mui/material';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

type OutlinedInputProps = MUIOutlinedInputProps;

const OutlinedInput: FC<OutlinedInputProps> = (outlinedInputProps) => {
  const { label, sx, ...outlinedInputRestProps } = outlinedInputProps;
  const combinedSx = {
    color: GREY,

    [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
      borderColor: UNSELECTED,
    },

    '&:hover': {
      [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
        borderColor: GREY,
      },
    },

    [`&.${muiOutlinedInputClasses.focused}`]: {
      color: TEXT,

      [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
        borderColor: GREY,

        '& legend': {
          paddingRight: label ? '1.2em' : 0,
        },
      },
    },

    ...sx,
  };

  return (
    <MUIOutlinedInput
      {...{
        label,
        ...outlinedInputRestProps,
        sx: combinedSx,
      }}
    />
  );
};

export type { OutlinedInputProps };

export default OutlinedInput;
