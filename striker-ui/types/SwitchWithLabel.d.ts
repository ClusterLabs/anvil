type SwitchWithLabelOptionalProps = {
  baseInputProps?: import('@mui/material/InputBase').InputBaseComponentProps;
  formControlLabelProps?: import('@mui/material/FormControlLabel').FormControlLabelProps;
  switchProps?: import('@mui/material/Switch').SwitchProps;
};

type SwitchWithLabelProps = SwitchWithLabelOptionalProps &
  Pick<
    import('@mui/material/Switch').SwitchProps,
    'checked' | 'id' | 'name' | 'onChange'
  > & {
    label: import('react').ReactNode;
  };
