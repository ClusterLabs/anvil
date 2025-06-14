import {
  FormControl as MuiFormControl,
  FormControlLabel as MuiFormControlLabel,
  FormLabel as MuiFormLabel,
  Radio as MuiRadio,
  radioClasses as muiRadioClasses,
  RadioGroup as MuiRadioGroup,
} from '@mui/material';
import { useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

const RadioGroupWithLabel = <Value = string,>(
  ...[props]: Parameters<React.FC<RadioGroupWithLabelProps<Value>>>
): ReturnType<React.FC<RadioGroupWithLabelProps<Value>>> => {
  const {
    formControlProps,
    formControlLabelProps,
    formLabelProps,
    id,
    label,
    name,
    onChange: onRadioGroupChange,
    radioItems,
    radioProps: { sx: radioSx, ...restRadioProps } = {},
    radioGroupProps,
    value,
  } = props;

  const labelElement = useMemo(
    () => (typeof label === 'string' ? <BodyText>{label}</BodyText> : label),
    [label],
  );
  const itemElements = useMemo(() => {
    const items = Object.entries(radioItems);

    return items.map(([itemId, { label: itemLabel, value: itemValue }]) => {
      const itemLabelElement =
        typeof itemLabel === 'string' ? (
          <BodyText>{itemLabel}</BodyText>
        ) : (
          itemLabel
        );

      return (
        <MuiFormControlLabel
          control={
            <MuiRadio
              {...restRadioProps}
              sx={{
                [`&.${muiRadioClasses.root}`]: {
                  color: GREY,
                },

                ...radioSx,
              }}
            />
          }
          key={`${id}-${itemId}`}
          value={itemValue}
          label={itemLabelElement}
          {...formControlLabelProps}
        />
      );
    });
  }, [formControlLabelProps, id, radioItems, radioSx, restRadioProps]);

  return (
    <MuiFormControl {...formControlProps}>
      <MuiFormLabel {...formLabelProps}>{labelElement}</MuiFormLabel>
      <MuiRadioGroup
        id={id}
        name={name}
        onChange={onRadioGroupChange}
        row
        value={value}
        {...radioGroupProps}
      >
        {itemElements}
      </MuiRadioGroup>
    </MuiFormControl>
  );
};

export default RadioGroupWithLabel;
