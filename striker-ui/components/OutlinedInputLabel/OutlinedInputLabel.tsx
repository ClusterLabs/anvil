import {
  InputLabel as MuiInputLabel,
  inputLabelClasses as muiInputLabelClasses,
  InputLabelProps as MuiInputLabelProps,
} from '@mui/material';
import { merge } from 'lodash';
import { useMemo } from 'react';

import { BLACK, BORDER_RADIUS, GREY } from '../../lib/consts/DEFAULT_THEME';

type OutlinedInputLabelProps = MuiInputLabelProps;

const OutlinedInputLabel: React.FC<OutlinedInputLabelProps> = (props) => {
  const { children, ...restProps } = props;

  const mergedProps = useMemo(
    () =>
      merge(
        {
          sx: {
            color: `${GREY}9F`,

            [`&.${muiInputLabelClasses.focused}`]: {
              backgroundColor: GREY,
              borderRadius: BORDER_RADIUS,
              color: BLACK,
              padding: '.1em .6em',
            },
          },
          variant: 'outlined',
        },
        restProps,
      ),
    [restProps],
  );

  return <MuiInputLabel {...mergedProps}>{children}</MuiInputLabel>;
};

export type { OutlinedInputLabelProps };

export default OutlinedInputLabel;
