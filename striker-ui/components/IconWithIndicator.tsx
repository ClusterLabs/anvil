import MuiSvgIcon from '@mui/material/SvgIcon';
import {
  Box as MuiBox,
  BoxProps as MuiBoxProps,
  SvgIconProps as MuiSvgIconProps,
} from '@mui/material';
import {
  createElement,
  forwardRef,
  useCallback,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import { BLACK, BLUE } from '../lib/consts/DEFAULT_THEME';

import FlexBox, { FlexBoxProps } from './FlexBox';
import { BodyText, BodyTextProps } from './Text';

type IndicatorValue = boolean | number;

type IconWithIndicatorOptionalPropsWithDefault = {
  iconProps?: MuiSvgIconProps;
  indicatorProps?: FlexBoxProps;
  indicatorTextProps?: BodyTextProps;
  initialIndicatorValue?: IndicatorValue;
};

type IconWithIndicatorOptionalProps = IconWithIndicatorOptionalPropsWithDefault;

type IconWithIndicatorProps = MuiBoxProps &
  IconWithIndicatorOptionalProps & {
    icon: typeof MuiSvgIcon;
  };

type IconWithIndicatorForwardedRefContent = {
  indicate?: (value: IndicatorValue) => void;
};

const CONTAINER_LENGTH = '1.7em';

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
      } = {},
      indicatorProps: {
        sx: indicatorSx,

        ...restIndicatorProps
      } = {},
      indicatorTextProps: {
        sx: indicatorTextSx,

        ...restIndicatorTextProps
      } = {},
      initialIndicatorValue = false,
      sx,
    },
    ref,
  ) => {
    const [indicatorValue, setIndicatorValue] = useState<boolean | number>(
      initialIndicatorValue,
    );

    const buildIndicator = useCallback(
      (
        indicatorContent: React.ReactNode,
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
          {Number(value) > INDICATOR_MAX ? `${INDICATOR_MAX}+` : value}
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
      <MuiBox
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
      </MuiBox>
    );
  },
);

IconWithIndicator.displayName = 'IconWithIndicator';

export type { IconWithIndicatorForwardedRefContent, IconWithIndicatorProps };

export default IconWithIndicator;
