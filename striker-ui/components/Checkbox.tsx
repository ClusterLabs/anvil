import {
  Checkbox as MUICheckbox,
  checkboxClasses as muiCheckboxClasses,
} from '@mui/material';
import { FC } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

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

export default Checkbox;
