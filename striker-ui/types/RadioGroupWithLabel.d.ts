type RadioItem<RadioItemValue> = {
  label: import('@mui/material').FormControlLabelProps['label'];
  value: RadioItemValue;
};

type RadioItemList<Value = string> = Record<string, RadioItem<Value>>;

type RadioGroupWithLabelOptionalProps = {
  formControlProps?: import('@mui/material').FormControlProps;
  formControlLabelProps?: import('@mui/material').FormControlLabelProps;
  formLabelProps?: import('@mui/material').FormLabelProps;
  label?: import('react').ReactNode;
  radioProps?: import('@mui/material').RadioProps;
  radioGroupProps?: import('@mui/material').RadioGroupProps;
};

type RadioGroupWithLabelProps<RadioItemValue = string> =
  RadioGroupWithLabelOptionalProps &
    Pick<
      import('@mui/material').RadioGroupProps,
      'name' | 'onChange' | 'value'
    > & {
      id: string;
      radioItems: RadioItemList<RadioItemValue>;
    };
