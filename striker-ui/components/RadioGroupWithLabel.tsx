import {
  FormControl as MUIFormControl,
  FormControlLabel as MUIFormControlLabel,
  FormLabel as MUIFormLabel,
  Radio as MUIRadio,
  radioClasses as muiRadioClasses,
  RadioGroup as MUIRadioGroup,
} from '@mui/material';
import { FC, useMemo } from 'react';

import { GREY } from '../lib/consts/DEFAULT_THEME';

import { BodyText } from './Text';

const RadioGroupWithLabel: FC<RadioGroupWithLabelProps> = ({
  formControlProps,
  formControlLabelProps,
  formLabelProps,
  id,
  label,
  onChange: onRadioGroupChange,
  radioItems,
  radioProps: { sx: radioSx, ...restRadioProps } = {},
  radioGroupProps,
}) => {
  const labelElement = useMemo(
    () => (typeof label === 'string' ? <BodyText>{label}</BodyText> : label),
    [label],
  );
  const itemElements = useMemo(() => {
    const items = Object.entries(radioItems);

    return items.map(([itemId, { label: itemLabel, value }]) => {
      const itemLabelElement =
        typeof itemLabel === 'string' ? (
          <BodyText>{itemLabel}</BodyText>
        ) : (
          itemLabel
        );

      return (
        <MUIFormControlLabel
          control={
            <MUIRadio
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
          value={value}
          label={itemLabelElement}
          {...formControlLabelProps}
        />
      );
    });
  }, [formControlLabelProps, id, radioItems, radioSx, restRadioProps]);

  return (
    <MUIFormControl {...formControlProps}>
      <MUIFormLabel {...formLabelProps}>{labelElement}</MUIFormLabel>
      <MUIRadioGroup onChange={onRadioGroupChange} row {...radioGroupProps}>
        {itemElements}
      </MUIRadioGroup>
    </MUIFormControl>
  );
};

export default RadioGroupWithLabel;
