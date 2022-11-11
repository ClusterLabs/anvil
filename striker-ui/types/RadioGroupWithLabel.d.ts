type RadioItem<RadioItemValue> = {
  label: import('@mui/material').FormControlLabelProps['label'];
  value: RadioItemValue;
};

type RadioGroupWithLabelOptionalProps = {
  formControlProps?: import('@mui/material').FormControlProps;
  formControlLabelProps?: import('@mui/material').FormControlLabelProps;
  formLabelProps?: import('@mui/material').FormLabelProps;
  label?: import('react').ReactNode;
  onChange?: import('@mui/material').RadioGroupProps['onChange'];
  radioProps?: import('@mui/material').RadioProps;
  radioGroupProps?: import('@mui/material').RadioGroupProps;
};

type RadioGroupWithLabelProps<RadioItemValue = string> =
  RadioGroupWithLabelOptionalProps & {
    id: string;
    radioItems: { [id: string]: RadioItem<RadioItemValue> };
  };
