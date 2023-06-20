type SwitchWithLabelOptionalProps = {
  baseInputProps?: import('@mui/material').InputBaseComponentProps;
  formControlLabelProps?: import('@mui/material').FormControlLabelProps;
  switchProps?: import('@mui/material').SwitchProps;
};

type SwitchWithLabelProps = SwitchWithLabelOptionalProps &
  Pick<
    import('@mui/material').SwitchProps,
    'checked' | 'id' | 'name' | 'onChange'
  > & {
    label: import('react').ReactNode;
  };
