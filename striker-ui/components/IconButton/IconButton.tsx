import MuiAddIcon from '@mui/icons-material/Add';
import MuiCloseIcon from '@mui/icons-material/Close';
import MuiContentCopy from '@mui/icons-material/ContentCopy';
import MuiDeleteIcon from '@mui/icons-material/Delete';
import MuiDoneIcon from '@mui/icons-material/Done';
import MuiEditIcon from '@mui/icons-material/Edit';
import MuiPlayCircleIcon from '@mui/icons-material/PlayCircle';
import MuiVisibilityIcon from '@mui/icons-material/Visibility';
import MuiVisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import MuiIconButton, {
  IconButtonProps as MuiIconButtonProps,
} from '@mui/material/IconButton';
import muiInputClasses from '@mui/material/Input/inputClasses';
import styled from '@mui/material/styles/styled';
import { createElement, useMemo } from 'react';

import {
  BLACK,
  BLUE,
  BORDER_RADIUS,
  DISABLED,
  GREY,
  RED,
} from '../../lib/consts/DEFAULT_THEME';

type IconButtonProps = IconButtonOptionalProps & MuiIconButtonProps;

const ContainedIconButton = styled(MuiIconButton)({
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

const RedContainedIconButton = styled(ContainedIconButton)({
  backgroundColor: RED,
  color: GREY,

  '&:hover': {
    backgroundColor: `${RED}F0`,
  },
});

const NormalIconButton = styled(MuiIconButton)({
  color: GREY,
});

const MAP_TO_ADD_ICON: IconButtonMapToStateIconBundle = {
  none: { iconType: MuiAddIcon },
};

const MAP_TO_CLOSE_ICON: IconButtonMapToStateIconBundle = {
  none: { iconType: MuiCloseIcon },
};

const MAP_TO_COPY_ICON: IconButtonMapToStateIconBundle = {
  none: { iconType: MuiContentCopy },
};

const MAP_TO_DELETE_ICON: IconButtonMapToStateIconBundle = {
  none: { iconType: MuiDeleteIcon },
};

const MAP_TO_EDIT_ICON: IconButtonMapToStateIconBundle = {
  false: { iconType: MuiEditIcon },
  true: { iconType: MuiDoneIcon, iconProps: { sx: { color: BLUE } } },
};

const MAP_TO_PLAY_ICON: IconButtonMapToStateIconBundle = {
  none: { iconType: MuiPlayCircleIcon },
};

const MAP_TO_VISIBILITY_ICON: IconButtonMapToStateIconBundle = {
  false: { iconType: MuiVisibilityIcon },
  true: { iconType: MuiVisibilityOffIcon },
};

const MAP_TO_MAP_PRESET: Record<
  IconButtonPresetMapToStateIconBundle,
  IconButtonMapToStateIconBundle
> = {
  add: MAP_TO_ADD_ICON,
  close: MAP_TO_CLOSE_ICON,
  copy: MAP_TO_COPY_ICON,
  delete: MAP_TO_DELETE_ICON,
  edit: MAP_TO_EDIT_ICON,
  play: MAP_TO_PLAY_ICON,
  visibility: MAP_TO_VISIBILITY_ICON,
};

const MAP_TO_VARIANT: Record<IconButtonVariant, CreatableComponent> = {
  contained: ContainedIconButton,
  normal: NormalIconButton,
  redcontained: RedContainedIconButton,
};

const IconButton: React.FC<IconButtonProps> = ({
  children,
  defaultIcon,
  iconProps,
  mapPreset,
  mapToIcon: externalMapToIcon,
  state = 'none',
  variant = 'contained',
  ...restIconButtonProps
}) => {
  const mapToIcon = useMemo<IconButtonMapToStateIconBundle | undefined>(
    () => externalMapToIcon ?? (mapPreset && MAP_TO_MAP_PRESET[mapPreset]),
    [externalMapToIcon, mapPreset],
  );

  const iconButtonContent = useMemo(() => {
    let result: React.ReactNode;

    if (mapToIcon) {
      const { iconType, iconProps: presetIconProps } = mapToIcon[state] ?? {
        iconType: defaultIcon,
      };

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
  }, [children, defaultIcon, iconProps, mapToIcon, state]);
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
