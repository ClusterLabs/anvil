type CreatableComponent = Parameters<typeof import('react').createElement>[0];

type IconButtonPresetMapToStateIconBundle =
  | 'add'
  | 'close'
  | 'copy'
  | 'delete'
  | 'edit'
  | 'play'
  | 'visibility';

type IconButtonStateIconBundle = {
  iconType: CreatableComponent;
  iconProps?: import('@mui/material/SvgIcon').SvgIconProps;
};

type IconButtonMapToStateIconBundle = Record<string, IconButtonStateIconBundle>;

type IconButtonVariant = 'contained' | 'normal' | 'redcontained';

type IconButtonMouseEventHandler =
  import('@mui/material/IconButton').IconButtonProps['onClick'];

type IconButtonOptionalProps = {
  defaultIcon?: CreatableComponent;
  iconProps?: import('@mui/material/SvgIcon').SvgIconProps;
  mapPreset?: IconButtonPresetMapToStateIconBundle;
  mapToIcon?: IconButtonMapToStateIconBundle;
  state?: string;
  variant?: IconButtonVariant;
};
