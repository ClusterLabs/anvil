import { FormControlLabel as MuiFormControlLabel } from '@mui/material';
import { useMemo } from 'react';

import Checkbox from './Checkbox';
import sxstring from '../lib/sxstring';
import { BodyText } from './Text';

const CheckboxWithLabel: React.FC<CheckboxWithLabelProps> = ({
  checkboxProps,
  checked,
  formControlLabelProps,
  label,
  onChange,
}) => {
  const labelElement = useMemo(() => sxstring(label, BodyText), [label]);

  return (
    <MuiFormControlLabel
      {...formControlLabelProps}
      control={
        <Checkbox {...checkboxProps} checked={checked} onChange={onChange} />
      }
      label={labelElement}
    />
  );
};

export default CheckboxWithLabel;
