import MuiFormControlLabel from '@mui/material/FormControlLabel';
import { useMemo } from 'react';

import Checkbox from './Checkbox';
import sxstring from '../lib/sxstring';
import { BodyText } from './Text';

const CheckboxWithLabel: React.FC<CheckboxWithLabelProps> = (props) => {
  const { checked, id, label, name, onChange, slotProps } = props;

  const labelElement = useMemo(() => sxstring(label, BodyText), [label]);

  return (
    <MuiFormControlLabel
      {...slotProps?.label}
      control={
        <Checkbox
          checked={checked}
          id={id}
          name={name}
          onChange={onChange}
          {...slotProps?.checkbox}
        />
      }
      label={labelElement}
    />
  );
};

export default CheckboxWithLabel;
