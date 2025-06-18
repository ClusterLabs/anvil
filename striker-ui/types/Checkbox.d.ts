type CheckboxOptionalProps = {
  invert?: boolean;
  thinPadding?: boolean;
};

type CheckboxProps = import('@mui/material/Checkbox').CheckboxProps &
  CheckboxOptionalProps;
