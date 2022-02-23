import {
  InputLabel as MUIInputLabel,
  inputLabelClasses as muiInputLabelClasses,
  InputLabelProps as MUIInputLabelProps,
} from '@mui/material';

import { BLACK, BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

const OutlinedInputLabel = ({
  children,
  htmlFor,
}: MUIInputLabelProps): JSX.Element => (
  <MUIInputLabel
    {...{ htmlFor }}
    sx={{
      color: GREY,

      [`&.${muiInputLabelClasses.focused}`]: {
        backgroundColor: GREY,
        borderRadius: BORDER_RADIUS,
        color: BLACK,
        padding: '.1em .6em',
      },
    }}
    variant="outlined"
  >
    {children}
  </MUIInputLabel>
);

export default OutlinedInputLabel;
