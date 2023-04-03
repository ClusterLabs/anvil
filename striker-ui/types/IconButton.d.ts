type CreatableComponent = Parameters<typeof import('react').createElement>[0];

type IconButtonPresetMapToStateIcon = 'edit' | 'visibility';

type IconButtonMapToStateIcon = Record<string, CreatableComponent>;

type IconButtonVariant = 'contained' | 'normal';

type IconButtonOptionalProps = {
  defaultIcon?: CreatableComponent;
  iconProps?: import('@mui/material').SvgIconProps;
  mapPreset?: IconButtonPresetMapToStateIcon;
  mapToIcon?: IconButtonMapToStateIcon;
  state?: string;
  variant?: IconButtonVariant;
};
