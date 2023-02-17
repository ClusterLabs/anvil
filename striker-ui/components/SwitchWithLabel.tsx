import { Switch, SxProps, Theme } from '@mui/material';
import { FC, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import FlexBox from './FlexBox';
import { BodyText } from './Text';

const SwitchWithLabel: FC<SwitchWithLabelProps> = ({
  checked: isChecked,
  flexBoxProps: { sx: flexBoxSx, ...restFlexBoxProps } = {},
  id: switchId,
  label,
  name: switchName,
  onChange,
  switchProps,
}) => {
  const combinedFlexBoxSx = useMemo<SxProps<Theme>>(
    () => ({
      '& > :first-child': {
        flexGrow: 1,
      },

      ...flexBoxSx,
    }),
    [flexBoxSx],
  );

  const labelElement = useMemo(
    () =>
      typeof label === 'string' ? (
        <BodyText inheritColour color={`${GREY}9F`}>
          {label}
        </BodyText>
      ) : (
        label
      ),
    [label],
  );

  return (
    <FlexBox row {...restFlexBoxProps} sx={combinedFlexBoxSx}>
      {labelElement}
      <Switch
        checked={isChecked}
        edge="end"
        id={switchId}
        name={switchName}
        onChange={onChange}
        {...switchProps}
      />
    </FlexBox>
  );
};

export default SwitchWithLabel;
