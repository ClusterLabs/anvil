import {
  Checkbox as MUICheckbox,
  checkboxClasses as muiCheckboxClasses,
  CheckboxProps as MUICheckboxProps,
} from '@mui/material';
import { FC } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

type CheckboxProps = MUICheckboxProps;

const Checkbox: FC<CheckboxProps> = ({ sx, ...checkboxProps }) => (
  <MUICheckbox
    {...{
      ...checkboxProps,
      sx: {
        color: GREY,

        [`&.${muiCheckboxClasses.checked}`]: { color: GREY },

        ...sx,
      },
    }}
  />
);

export type { CheckboxProps };

export default Checkbox;
