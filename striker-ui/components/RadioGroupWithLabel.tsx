import MuiFormControl from '@mui/material/FormControl';
import MuiFormControlLabel from '@mui/material/FormControlLabel';
import MuiFormLabel from '@mui/material/FormLabel';
import MuiRadio, { radioClasses as muiRadioClasses } from '@mui/material/Radio';
import MuiRadioGroup from '@mui/material/RadioGroup';
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
