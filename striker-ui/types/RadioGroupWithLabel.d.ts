type RadioItem<RadioItemValue> = {
  label: import('@mui/material/FormControlLabel').FormControlLabelProps['label'];
  value: RadioItemValue;
};

type RadioItemList<Value = string> = Record<string, RadioItem<Value>>;

type RadioGroupWithLabelOptionalProps = {
  formControlProps?: import('@mui/material/FormControl').FormControlProps;
  formControlLabelProps?: import('@mui/material/FormControlLabel').FormControlLabelProps;
  formLabelProps?: import('@mui/material/FormLabel').FormLabelProps;
  label?: import('react').ReactNode;
  radioProps?: import('@mui/material/Radio').RadioProps;
  radioGroupProps?: import('@mui/material/RadioGroup').RadioGroupProps;
};

type RadioGroupWithLabelProps<RadioItemValue = string> =
  RadioGroupWithLabelOptionalProps &
    Pick<
      import('@mui/material/RadioGroup').RadioGroupProps,
      'name' | 'onChange' | 'value'
    > & {
      id: string;
      radioItems: RadioItemList<RadioItemValue>;
    };
