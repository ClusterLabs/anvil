import {
  FormControlLabel as MUIFormControlLabel,
  styled,
  Switch as MUISwitch,
} from '@mui/material';
import { FC, ReactElement, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

const SwitchFormControlLabel = styled(MUIFormControlLabel)({
  height: '3.5em',
  marginLeft: 0,
  width: '100%',
});

const SwitchWithLabel: FC<SwitchWithLabelProps> = ({
  baseInputProps,
  checked: isChecked,
  formControlLabelProps,
  id: switchId,
  label,
  name: switchName,
  onChange,
  switchProps,
}) => {
  const labelElement = useMemo<ReactElement>(
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
        componentsProps={{ typography: { flexGrow: 1 } }}
        control={
          <MUISwitch
            checked={isChecked}
            edge="end"
            name={switchName}
            onChange={onChange}
            {...switchProps}
          />
        }
        label={labelElement}
        labelPlacement="start"
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
