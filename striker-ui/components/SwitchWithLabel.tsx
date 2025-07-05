import MuiFormControlLabel from '@mui/material/FormControlLabel';
import MuiSwitch from '@mui/material/Switch';
import styled from '@mui/material/styles/styled';
import { useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import sxstring from '../lib/sxstring';
import { BodyText } from './Text';

const SwitchFormControlLabel = styled(MuiFormControlLabel)({
  height: '3.5em',
  marginLeft: 0,
  width: '100%',
});

const SwitchWithLabel: React.FC<SwitchWithLabelProps> = ({
  baseInputProps,
  checked: isChecked,
  formControlLabelProps,
  id: switchId,
  label,
  name: switchName,
  onChange,
  switchProps,
}) => {
  const labelElement = useMemo<React.ReactNode>(
    () =>
      sxstring(label, BodyText, {
        color: `${GREY}AF`,
        inheritColour: true,
      }),
    [label],
  );

  return (
    <>
      <SwitchFormControlLabel
        control={
          <MuiSwitch
            checked={isChecked}
            edge="end"
            name={switchName}
            onChange={onChange}
            {...switchProps}
          />
        }
        label={labelElement}
        labelPlacement="start"
        slotProps={{
          typography: {
            flexGrow: 1,
          },
        }}
        {...formControlLabelProps}
      />
      <input
        checked={isChecked}
        hidden
        id={switchId}
        readOnly
        type="checkbox"
        {...baseInputProps}
      />
    </>
  );
};

export default SwitchWithLabel;
