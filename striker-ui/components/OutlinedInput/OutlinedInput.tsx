import {
  OutlinedInput as MUIOutlinedInput,
  outlinedInputClasses as muiOutlinedInputClasses,
  styled,
} from '@mui/material';

import { GREY, TEXT, UNSELECTED } from '../../lib/consts/DEFAULT_THEME';

const OutlinedInput = styled(MUIOutlinedInput)({
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
        paddingRight: '1.2em',
      },
    },
  },
});

export default OutlinedInput;
