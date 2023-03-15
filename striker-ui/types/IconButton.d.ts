type CreatableComponent = Parameters<typeof import('react').createElement>[0];

type IconButtonPresetMapToStateIconBundle =
  | 'add'
  | 'close'
  | 'edit'
  | 'visibility';

type IconButtonStateIconBundle = {
  iconType: CreatableComponent;
  iconProps?: import('@mui/material').SvgIconProps;
};

type IconButtonMapToStateIconBundle = Record<string, IconButtonStateIconBundle>;

type IconButtonVariant = 'contained' | 'normal';

type IconButtonOptionalProps = {
  defaultIcon?: CreatableComponent;
  iconProps?: import('@mui/material').SvgIconProps;
  mapPreset?: IconButtonPresetMapToStateIconBundle;
  mapToIcon?: IconButtonMapToStateIconBundle;
  state?: string;
  variant?: IconButtonVariant;
};
