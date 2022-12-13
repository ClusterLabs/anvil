import { SvgIconComponent } from '@mui/icons-material';
import {
  Box as MUIBox,
  BoxProps as MUIBoxProps,
  SvgIconProps,
} from '@mui/material';
import {
  createElement,
  forwardRef,
  ReactNode,
  useCallback,
  useImperativeHandle,
  useMemo,
} from 'react';

import { BLACK, BLUE } from '../lib/consts/DEFAULT_THEME';

import FlexBox, { FlexBoxProps } from './FlexBox';
import { BodyText, BodyTextProps } from './Text';
import useProtect from '../hooks/useProtect';
import useProtectedState from '../hooks/useProtectedState';

type IndicatorValue = boolean | number;

type IconWithIndicatorOptionalPropsWithDefault = {
  iconProps?: SvgIconProps;
  indicatorProps?: FlexBoxProps;
  indicatorTextProps?: BodyTextProps;
  initialIndicatorValue?: IndicatorValue;
};

type IconWithIndicatorOptionalProps = IconWithIndicatorOptionalPropsWithDefault;

type IconWithIndicatorProps = MUIBoxProps &
  IconWithIndicatorOptionalProps & {
    icon: SvgIconComponent;
  };

type IconWithIndicatorForwardedRefContent = {
  indicate?: (value: IndicatorValue) => void;
};

const CONTAINER_LENGTH = '1.7em';
const ICON_WITH_INDICATOR_DEFAULT_PROPS: Required<IconWithIndicatorOptionalPropsWithDefault> =
  {
    iconProps: {},
    indicatorProps: {},
    indicatorTextProps: {},
    initialIndicatorValue: false,
  };
const INDICATOR_LENGTH = { small: '24%', medium: '50%' };
const INDICATOR_MAX = 9;
const INDICATOR_OFFSET = { small: '.1rem', medium: '0rem' };

const IconWithIndicator = forwardRef<
  IconWithIndicatorForwardedRefContent,
  IconWithIndicatorProps
>(
  (
    {
      icon,
      iconProps: {
        sx: iconSx,

        ...restIconProps
      } = ICON_WITH_INDICATOR_DEFAULT_PROPS.iconProps,
      indicatorProps: {
        sx: indicatorSx,

        ...restIndicatorProps
      } = ICON_WITH_INDICATOR_DEFAULT_PROPS.indicatorProps,
      indicatorTextProps: {
        sx: indicatorTextSx,

        ...restIndicatorTextProps
      } = ICON_WITH_INDICATOR_DEFAULT_PROPS.indicatorTextProps,
      initialIndicatorValue = ICON_WITH_INDICATOR_DEFAULT_PROPS.initialIndicatorValue,
      sx,
    },
    ref,
  ) => {
    const { protect } = useProtect();
    const [indicatorValue, setIndicatorValue] = useProtectedState<
      boolean | number
    >(initialIndicatorValue, protect);

    const buildIndicator = useCallback(
      (
        indicatorContent: ReactNode,
        indicatorLength: number | string,
        indicatorOffset: number | string,
      ) => (
        <FlexBox
          row
          {...restIndicatorProps}
          sx={{
            backgroundColor: BLUE,
            borderColor: BLACK,
            borderRadius: '50%',
            borderStyle: 'solid',
            borderWidth: '.1em',
            bottom: indicatorOffset,
            boxSizing: 'content-box',
            height: 0,
            justifyContent: 'center',
            paddingBottom: indicatorLength,
            position: 'absolute',
            right: indicatorOffset,
            width: indicatorLength,

            ...indicatorSx,
          }}
        >
          {indicatorContent}
        </FlexBox>
      ),
      [indicatorSx, restIndicatorProps],
    );
    const buildIndicatorText = useCallback(
      (value: IndicatorValue) => (
        <BodyText
          {...restIndicatorTextProps}
          sx={{
            fontWeight: '500',
            paddingTop: '100%',

            ...indicatorTextSx,
          }}
        >
          {value > INDICATOR_MAX ? `${INDICATOR_MAX}+` : value}
        </BodyText>
      ),
      [indicatorTextSx, restIndicatorTextProps],
    );

    const indicator = useMemo(() => {
      let result;

      if (indicatorValue) {
        let indicatorContent;
        let indicatorLength = INDICATOR_LENGTH.small;
        let indicatorOffset = INDICATOR_OFFSET.small;

        if (Number.isFinite(indicatorValue)) {
          indicatorContent = buildIndicatorText(indicatorValue);
          indicatorLength = INDICATOR_LENGTH.medium;
          indicatorOffset = INDICATOR_OFFSET.medium;
        }

        result = buildIndicator(
          indicatorContent,
          indicatorLength,
          indicatorOffset,
        );
      }

      return result;
    }, [buildIndicator, buildIndicatorText, indicatorValue]);

    useImperativeHandle(
      ref,
      () => ({
        indicate: (value) => setIndicatorValue(value),
      }),
      [setIndicatorValue],
    );

    return (
      <MUIBox
        sx={{
          height: CONTAINER_LENGTH,
          width: CONTAINER_LENGTH,
          position: 'relative',
          ...sx,
        }}
      >
        {createElement(icon, {
          ...restIconProps,

          sx: { height: '100%', width: '100%', ...iconSx },
        })}
        {indicator}
      </MUIBox>
    );
  },
);

IconWithIndicator.defaultProps = ICON_WITH_INDICATOR_DEFAULT_PROPS;
IconWithIndicator.displayName = 'IconWithIndicator';

export type { IconWithIndicatorForwardedRefContent, IconWithIndicatorProps };

export default IconWithIndicator;
