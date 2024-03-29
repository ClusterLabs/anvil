type CheckboxWithLabelOptionalProps = Partial<
  Pick<CheckboxProps, 'checked' | 'onChange'>
> & {
  checkboxProps?: Partial<CheckboxProps>;
  formControlLabelProps?: Partial<
    import('@mui/material').FormControlLabelProps
  >;
};

type CheckboxWithLabelProps = CheckboxWithLabelOptionalProps & {
  label: import('@mui/material').FormControlLabelProps['label'];
};
