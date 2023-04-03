type SwitchWithLabelOptionalProps = {
  flexBoxProps?: import('../components/FlexBox').FlexBoxProps;
  switchProps?: import('@mui/material').SwitchProps;
};

type SwitchWithLabelProps = SwitchWithLabelOptionalProps &
  Pick<
    import('@mui/material').SwitchProps,
    'checked' | 'id' | 'name' | 'onChange'
  > & {
    label: import('react').ReactNode;
  };
