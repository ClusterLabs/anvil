import { FormControlLabel } from '@mui/material';
import { FC, useMemo } from 'react';

import Checkbox from './Checkbox';
import { BodyText } from './Text';

const CheckboxWithLabel: FC<CheckboxWithLabelProps> = ({
  checkboxProps,
  checked,
  formControlLabelProps,
  label,
  onChange,
}) => {
  const labelElement = useMemo(
    () => (typeof label === 'string' ? <BodyText>{label}</BodyText> : label),
    [label],
  );

  return (
    <FormControlLabel
      {...formControlLabelProps}
      control={
        <Checkbox {...checkboxProps} checked={checked} onChange={onChange} />
      }
      label={labelElement}
    />
  );
};

export default CheckboxWithLabel;
