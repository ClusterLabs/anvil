import {
  Done as MUIDoneIcon,
  Edit as MUIEditIcon,
  Visibility as MUIVisibilityIcon,
  VisibilityOff as MUIVisibilityOffIcon,
} from '@mui/icons-material';
import {
  IconButton as MUIIconButton,
  IconButtonProps as MUIIconButtonProps,
  inputClasses as muiInputClasses,
  styled,
} from '@mui/material';
import { createElement, FC, ReactNode, useMemo } from 'react';

import {
  BLACK,
  BLUE,
  BORDER_RADIUS,
  DISABLED,
  GREY,
} from '../../lib/consts/DEFAULT_THEME';

type IconButtonProps = IconButtonOptionalProps & MUIIconButtonProps;

const ContainedIconButton = styled(MUIIconButton)({
  borderRadius: BORDER_RADIUS,
  backgroundColor: GREY,
  color: BLACK,

  '&:hover': {
    backgroundColor: `${GREY}F0`,
  },

  [`&.${muiInputClasses.disabled}`]: {
    backgroundColor: DISABLED,
  },
});

const NormalIconButton = styled(MUIIconButton)({
  color: GREY,
});

const MAP_TO_VISIBILITY_ICON: IconButtonMapToStateIconBundle = {
  false: { iconType: MUIVisibilityIcon },
  true: { iconType: MUIVisibilityOffIcon },
};

const MAP_TO_EDIT_ICON: IconButtonMapToStateIconBundle = {
  false: { iconType: MUIEditIcon },
  true: { iconType: MUIDoneIcon, iconProps: { sx: { color: BLUE } } },
};

const MAP_TO_MAP_PRESET: Record<
  IconButtonPresetMapToStateIconBundle,
  IconButtonMapToStateIconBundle
> = {
  edit: MAP_TO_EDIT_ICON,
  visibility: MAP_TO_VISIBILITY_ICON,
};

const MAP_TO_VARIANT: Record<IconButtonVariant, CreatableComponent> = {
  contained: ContainedIconButton,
  normal: NormalIconButton,
};

const IconButton: FC<IconButtonProps> = ({
  children,
  defaultIcon,
  iconProps,
  mapPreset,
  mapToIcon: externalMapToIcon,
  state,
  variant = 'contained',
  ...restIconButtonProps
}) => {
  const mapToIcon = useMemo<IconButtonMapToStateIconBundle | undefined>(
    () => externalMapToIcon ?? (mapPreset && MAP_TO_MAP_PRESET[mapPreset]),
    [externalMapToIcon, mapPreset],
  );

  const defaultIconBundle = useMemo<Partial<IconButtonStateIconBundle>>(
    () => ({ iconType: defaultIcon }),
    [defaultIcon],
  );

  const iconButtonContent = useMemo(() => {
    let result: ReactNode;

    if (mapToIcon) {
      const { iconType, iconProps: presetIconProps } = state
        ? mapToIcon[state] ?? defaultIconBundle
        : defaultIconBundle;

      if (iconType) {
        result = createElement(iconType, {
          ...presetIconProps,
          ...iconProps,
        });
      }
    } else {
      result = children;
    }

    return result;
  }, [mapToIcon, state, defaultIconBundle, iconProps, children]);
  const iconButtonElementType = useMemo(
    () => MAP_TO_VARIANT[variant],
    [variant],
  );

  return createElement(
    iconButtonElementType,
    restIconButtonProps,
    iconButtonContent,
  );
};

export type { IconButtonProps };

export default IconButton;
