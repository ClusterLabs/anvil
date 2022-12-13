import { Star as MUIRequiredIcon } from '@mui/icons-material';
import {
  Box,
  InputLabel as MUIInputLabel,
  inputLabelClasses as muiInputLabelClasses,
  InputLabelProps as MUIInputLabelProps,
  svgIconClasses as muiSvgIconClasses,
} from '@mui/material';

import { BLACK, BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

type OutlinedInputLabelOptionalProps = {
  isNotifyRequired?: boolean;
};

type OutlinedInputLabelProps = MUIInputLabelProps &
  OutlinedInputLabelOptionalProps;

const OutlinedInputLabel = (
  inputLabelProps: OutlinedInputLabelProps,
): JSX.Element => {
  const {
    children,
    isNotifyRequired,
    sx,
    variant = 'outlined',
    ...inputLabelRestProps
  } = inputLabelProps;
  const combinedSx = {
    color: `${GREY}9F`,

    [`& .${muiSvgIconClasses.root}`]: {
      color: GREY,
    },

    [`&.${muiInputLabelClasses.focused}`]: {
      backgroundColor: GREY,
      borderRadius: BORDER_RADIUS,
      color: BLACK,
      padding: '.1em .6em',
    },

    [`&.${muiInputLabelClasses.shrink} .${muiSvgIconClasses.root}`]: {
      display: 'none',
    },

    ...sx,
  };

  return (
    <MUIInputLabel
      {...{
        // 1. Specify default props.
        variant,
        // 2. Override defaults with given props.
        ...inputLabelRestProps,
        // 3. Combine the default and given for props that can be both extended or override.
        sx: combinedSx,
      }}
    >
      <Box
        sx={{
          alignItems: 'center',
          display: 'flex',
          flexDirection: 'row',
        }}
      >
        {isNotifyRequired && (
          <MUIRequiredIcon
            sx={{ marginLeft: '-.2rem', marginRight: '.4rem' }}
          />
        )}
        {children}
      </Box>
    </MUIInputLabel>
  );
};

export type { OutlinedInputLabelProps };

export default OutlinedInputLabel;
