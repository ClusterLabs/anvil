type CheckboxWithLabelOptionalProps = Partial<
  Pick<CheckboxProps, 'checked' | 'id' | 'name' | 'onChange'>
> & {
  slotProps?: {
    checkbox?: Partial<CheckboxProps>;
    label?: import('@mui/material/FormControlLabel').FormControlLabelProps;
  };
};

type CheckboxWithLabelProps = CheckboxWithLabelOptionalProps & {
  label: React.ReactNode;
};
