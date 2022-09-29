import { SvgIconComponent } from '@mui/icons-material';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  SvgIconProps,
} from '@mui/material';
import { createElement, FC } from 'react';

import { BLACK, BLUE } from '../lib/consts/DEFAULT_THEME';

import FlexBox, { FlexBoxProps } from './FlexBox';

type IconWithIndicatorOptionalPropsWithDefault = {
  iconProps?: SvgIconProps;
  indicatorProps?: FlexBoxProps;
};

type IconWithIndicatorOptionalProps = IconWithIndicatorOptionalPropsWithDefault;

type IconWithIndicatorProps = MUIBoxProps &
  IconWithIndicatorOptionalProps & {
    icon: SvgIconComponent;
  };

const ICON_WITH_INDICATOR_DEFAULT_PROPS: Required<IconWithIndicatorOptionalPropsWithDefault> =
  {
    iconProps: {},
    indicatorProps: {},
  };

const IconWithIndicator: FC<IconWithIndicatorProps> = ({
  icon,
  iconProps: {
    sx: iconSx,

    ...restIconProps
  } = ICON_WITH_INDICATOR_DEFAULT_PROPS.iconProps,
  indicatorProps: {
    sx: indicatorSx,

    ...restIndicatorProps
  } = ICON_WITH_INDICATOR_DEFAULT_PROPS.indicatorProps,
  sx,
}) => {
  const containerLength = '1.7em';
  const indicatorLength = '24%';
  const indicatorOffset = '.1rem';

  return (
    <MUIBox
      sx={{
        height: containerLength,
        width: containerLength,
        position: 'relative',
        ...sx,
      }}
    >
      {createElement(icon, {
        ...restIconProps,

        sx: { height: '100%', width: '100%', ...iconSx },
      })}
      {createElement(FlexBox, {
        row: true,

        ...restIndicatorProps,

        sx: {
          backgroundColor: BLUE,
          borderColor: BLACK,
          borderRadius: '50%',
          borderStyle: 'solid',
          borderWidth: '.2rem',
          bottom: indicatorOffset,
          boxSizing: 'content-box',
          height: 0,
          justifyContent: 'center',
          paddingBottom: indicatorLength,
          position: 'absolute',
          right: indicatorOffset,
          width: indicatorLength,

          ...indicatorSx,
        },
      })}
    </MUIBox>
  );
};

IconWithIndicator.defaultProps = ICON_WITH_INDICATOR_DEFAULT_PROPS;

export default IconWithIndicator;
