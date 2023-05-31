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

const MAP_TO_VISIBILITY_ICON: IconButtonMapToStateIcon = {
  false: MUIVisibilityIcon,
  true: MUIVisibilityOffIcon,
};

const MAP_TO_EDIT_ICON: IconButtonMapToStateIcon = {
  false: MUIEditIcon,
  true: MUIDoneIcon,
};

const MAP_TO_MAP_PRESET: Record<
  IconButtonPresetMapToStateIcon,
  IconButtonMapToStateIcon
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
  const mapToIcon = useMemo<IconButtonMapToStateIcon | undefined>(
    () => externalMapToIcon ?? (mapPreset && MAP_TO_MAP_PRESET[mapPreset]),
    [externalMapToIcon, mapPreset],
  );

  const iconButtonContent = useMemo(() => {
    let result: ReactNode;

    if (mapToIcon) {
      const iconElementType: CreatableComponent | undefined = state
        ? mapToIcon[state] ?? defaultIcon
        : defaultIcon;

      if (iconElementType) {
        result = createElement(iconElementType, iconProps);
      }
    } else {
      result = children;
    }

    return result;
  }, [children, mapToIcon, state, defaultIcon, iconProps]);
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
