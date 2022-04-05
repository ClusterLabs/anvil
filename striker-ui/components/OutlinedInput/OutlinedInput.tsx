import {
  OutlinedInput as MUIOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
} from '@mui/material';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

const OutlinedInput = (
  outlinedInputProps: MUIOutlinedInputProps,
): JSX.Element => {
  const { label, sx } = outlinedInputProps;
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
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        ...outlinedInputProps,
        sx: combinedSx,
      }}
    />
  );
};

export default OutlinedInput;
