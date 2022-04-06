import { useState } from 'react';
import {
  Box,
  inputLabelClasses as muiInputLabelClasses,
  outlinedInputClasses as muiOutlinedInputClasses,
  Slider as MUISlider,
  sliderClasses as muiSliderClasses,
  SliderProps as MUISliderProps,
  TypographyProps as MUITypographyProps,
} from '@mui/material';

import { BORDER_RADIUS, GREY } from '../lib/consts/DEFAULT_THEME';

import OutlinedInput from './OutlinedInput';
import OutlinedInputLabel from './OutlinedInputLabel';
import { BodyText } from './Text';

type SliderOnBlur = Exclude<MUISliderProps['onBlur'], undefined>;
type SliderOnChange = Exclude<MUISliderProps['onChange'], undefined>;
type SliderOnFocus = Exclude<MUISliderProps['onFocus'], undefined>;
type SliderValue = Exclude<MUISliderProps['value'], undefined>;

type SliderOptionalProps = {
  isAllowTextInput?: boolean;
  labelId?: string;
  labelProps?: MUITypographyProps;
  sliderProps?: MUISliderProps;
};

type SliderProps = {
  label: string;
  value: SliderValue;
} & SliderOptionalProps;

const SLIDER_DEFAULT_PROPS: Required<SliderOptionalProps> = {
  isAllowTextInput: false,
  labelId: '',
  labelProps: {},
  sliderProps: {},
};

const createInputLabelDecorator = (label: string, isFocused: boolean) => {
  const borderColor = GREY;
  const borderStyle = 'solid';
  const borderWidth = isFocused ? '2px 0 0 0' : '1px 0 0 0';
  const content = '""';
  const opacity = isFocused ? '1' : '0.3';

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'row',
        position: 'absolute',
        width: '24em',

        '> :last-child': {
          flexGrow: 1,
        },
      }}
    >
      <Box
        sx={{
          borderColor,
          borderStyle,
          borderWidth,
          content,
          opacity,
          width: '.6em',
        }}
      />
      <BodyText
        sx={{
          fontSize: '.75em',
          margin: isFocused ? '0 1em 0 1em' : '0 .6em 0 .4em',
          visibility: 'hidden',
        }}
        text={label}
      />
      <Box
        sx={{
          borderColor,
          borderStyle,
          borderWidth,
          content,
          opacity,
        }}
      />
    </Box>
  );
};

const createOutlinedInput = (
  sliderValue: SliderValue,
  isFocused: boolean,
  onFocus: SliderOnFocus,
  onBlur: SliderOnBlur,
) => (
  <OutlinedInput
    {...{
      className: isFocused ? muiOutlinedInputClasses.focused : '',
      onBlur,
      onFocus,
      value: sliderValue,
    }}
  />
);

const Slider = ({
  isAllowTextInput,
  label,
  labelId,
  labelProps,
  sliderProps,
  value,
}: SliderProps): JSX.Element => {
  const { sx: labelSx } = labelProps ?? SLIDER_DEFAULT_PROPS.labelProps;
  const {
    onChange: sliderChangeCallback,
    sx: sliderSx,
    valueLabelDisplay: sliderValueLabelDisplay,
  } = sliderProps ?? SLIDER_DEFAULT_PROPS.sliderProps;

  const [sliderValue, setSliderValue] = useState<SliderValue>(value);
  const [isFocused, setIsFocused] = useState<boolean>(false);

  const handleLocalSliderBlur: SliderOnBlur = () => {
    setIsFocused(false);
  };

  const handleLocalSliderChange: SliderOnChange = (event, newValue) => {
    setSliderValue(newValue);
  };

  const handleLocalSliderFocus: SliderOnFocus = () => {
    setIsFocused(true);
  };

  const handleSliderChange = sliderChangeCallback
    ? (...args: Parameters<SliderOnChange>) => {
        handleLocalSliderChange(...args);
        sliderChangeCallback(...args);
      }
    : handleLocalSliderChange;

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column' }}>
      <OutlinedInputLabel
        {...{
          className: isFocused ? muiInputLabelClasses.focused : '',
          id: labelId,
          sx: {
            ...labelSx,
          },
        }}
      >
        {label}
      </OutlinedInputLabel>
      {createInputLabelDecorator(label, isFocused)}
      <Box
        sx={{
          alignItems: 'center',
          display: 'flex',
          flexDirection: 'row',
          '> :first-child': { flexGrow: 1 },
        }}
      >
        <MUISlider
          {...{
            'aria-labelledby': labelId,
            onBlur: handleLocalSliderBlur,
            onChange: handleSliderChange,
            onFocus: handleLocalSliderFocus,
            sx: {
              color: GREY,
              marginLeft: '13px',
              marginRight: '26px',

              [`& .${muiSliderClasses.thumb}`]: {
                borderRadius: BORDER_RADIUS,
                transform: 'translate(-50%, -50%) rotate(45deg)',
              },

              ...sliderSx,
            },
            value: sliderValue,
            valueLabelDisplay: sliderValueLabelDisplay,
          }}
        />
        {isAllowTextInput &&
          createOutlinedInput(
            sliderValue,
            isFocused,
            handleLocalSliderFocus,
            handleLocalSliderBlur,
          )}
      </Box>
    </Box>
  );
};

Slider.defaultProps = SLIDER_DEFAULT_PROPS;

export type { SliderProps };

export default Slider;
