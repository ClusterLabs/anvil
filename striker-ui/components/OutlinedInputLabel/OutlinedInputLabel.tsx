import {
  InputLabel as MUIInputLabel,
  inputLabelClasses as muiInputLabelClasses,
  InputLabelProps as MUIInputLabelProps,
} from '@mui/material';

import { BLACK, BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

const OutlinedInputLabel = (
  inputLabelProps: MUIInputLabelProps,
): JSX.Element => {
  const { children, sx } = inputLabelProps;
  const combinedSx = {
    color: GREY,

    [`&.${muiInputLabelClasses.focused}`]: {
      backgroundColor: GREY,
      borderRadius: BORDER_RADIUS,
      color: BLACK,
      padding: '.1em .6em',
    },

    ...sx,
  };

  return (
    <MUIInputLabel
      // eslint-disable-next-line react/jsx-props-no-spreading
      {...{
        // 1. Specify default props.
        variant: 'outlined',
        // 2. Override defaults with given props.
        ...inputLabelProps,
        // 3. Combine the default and given for props that can be both extended or override.
        sx: combinedSx,
      }}
    >
      {children}
    </MUIInputLabel>
  );
};

export default OutlinedInputLabel;
