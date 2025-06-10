import {
  FormControlLabel as MuiFormControlLabel,
  styled,
  Switch as MuiSwitch,
} from '@mui/material';
import { useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

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
  const labelElement = useMemo<React.ReactElement>(
    () =>
      typeof label === 'string' ? (
        <BodyText inheritColour color={`${GREY}AF`}>
          {label}
        </BodyText>
      ) : (
        <>{label}</>
      ),
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
