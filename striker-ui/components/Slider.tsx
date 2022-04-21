import { useState } from 'react';
import {
  Box,
  inputLabelClasses as muiInputLabelClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
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
  sliderProps?: Omit<MUISliderProps, 'onChange'> & {
    onChange?: (value: number | number[]) => void;
  };
};

type SliderProps = {
  label: string;
  value: SliderValue;
} & SliderOptionalProps;

type TextInputOnChange = Exclude<MUIOutlinedInputProps['onChange'], undefined>;

const SLIDER_DEFAULT_PROPS: Required<SliderOptionalProps> = {
  isAllowTextInput: false,
  labelId: '',
  labelProps: {},
  sliderProps: {},
};

const createInputLabelDecorator = ({
  isFocused,
  label,
}: {
  isFocused?: boolean;
  label: string;
}) => {
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
        width: '100%',

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

const createOutlinedInput = ({
  isFocused,
  max,
  min,
  onBlur,
  onChange,
  onFocus,
  sliderValue,
  sx,
}: {
  isFocused?: boolean;
  max?: number;
  min?: number;
  onBlur?: SliderOnBlur;
  onChange?: TextInputOnChange;
  onFocus?: SliderOnFocus;
  sliderValue?: SliderValue;
  sx?: MUISliderProps['sx'];
}) => (
  <OutlinedInput
    {...{
      className: isFocused ? muiOutlinedInputClasses.focused : '',
      inputProps: { max, min },
      onBlur,
      onChange,
      onFocus,
      sx,
      type: 'number',
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
    max,
    min,
    onChange: sliderChangeCallback,
    sx: sliderSx,
    valueLabelDisplay: sliderValueLabelDisplay,
  } = sliderProps ?? SLIDER_DEFAULT_PROPS.sliderProps;

  const [isFocused, setIsFocused] = useState<boolean>(false);

  const handleLocalSliderBlur: SliderOnBlur = () => {
    setIsFocused(false);
  };

  const handleLocalSliderFocus: SliderOnFocus = () => {
    setIsFocused(true);
  };

  const handleSliderChange: SliderOnChange = (event, newValue) => {
    sliderChangeCallback?.call(null, newValue);
  };

  const handleTextInputChange: TextInputOnChange = ({
    target: { value: newValue },
  }) => {
    sliderChangeCallback?.call(null, parseFloat(newValue));
  };

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
      {createInputLabelDecorator({ isFocused, label })}
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
            max,
            min,
            onBlur: handleLocalSliderBlur,
            onChange: handleSliderChange,
            onFocus: handleLocalSliderFocus,
            sx: {
              color: GREY,
              marginLeft: '1em',
              marginRight: '1em',

              [`& .${muiSliderClasses.thumb}`]: {
                borderRadius: BORDER_RADIUS,
                transform: 'translate(-50%, -50%) rotate(45deg)',
              },

              ...sliderSx,
            },
            value,
            valueLabelDisplay: sliderValueLabelDisplay,
          }}
        />
        {createOutlinedInput({
          isFocused,
          max,
          min,
          onBlur: handleLocalSliderBlur,
          onChange: handleTextInputChange,
          onFocus: handleLocalSliderFocus,
          sliderValue: value,
          sx: isAllowTextInput
            ? undefined
            : {
                visibility: 'collapse',
              },
        })}
      </Box>
    </Box>
  );
};

Slider.defaultProps = SLIDER_DEFAULT_PROPS;

export type { SliderProps };

export default Slider;
