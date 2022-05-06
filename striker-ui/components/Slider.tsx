import { useState } from 'react';
import {
  Box,
  inputLabelClasses as muiInputLabelClasses,
  OutlinedInputProps as MUIOutlinedInputProps,
  outlinedInputClasses as muiOutlinedInputClasses,
  Slider as MUISlider,
  sliderClasses as muiSliderClasses,
  SliderProps as MUISliderProps,
  FormControl,
} from '@mui/material';

import { BORDER_RADIUS, GREY } from '../lib/consts/DEFAULT_THEME';

import InputMessageBox from './InputMessageBox';
import { MessageBoxProps } from './MessageBox';
import OutlinedInput, { OutlinedInputProps } from './OutlinedInput';
import OutlinedInputLabel, {
  OutlinedInputLabelProps,
} from './OutlinedInputLabel';
import { BodyText } from './Text';

type SliderOnBlur = Exclude<MUISliderProps['onBlur'], undefined>;
type SliderOnChange = Exclude<MUISliderProps['onChange'], undefined>;
type SliderOnFocus = Exclude<MUISliderProps['onFocus'], undefined>;
type SliderValue = Exclude<MUISliderProps['value'], undefined>;

type SliderOptionalProps = {
  inputLabelProps?: Partial<OutlinedInputLabelProps>;
  isAllowTextInput?: boolean;
  labelId?: string;
  messageBoxProps?: Partial<MessageBoxProps>;
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
  inputLabelProps: {},
  isAllowTextInput: false,
  labelId: '',
  messageBoxProps: {},
  sliderProps: {},
};

const SLIDER_INPUT_LABEL_DECORATOR_CLASS_PREFIX = 'SliderInputLabelDecorator';
const SLIDER_INPUT_LABEL_DECORATOR_CLASSES = {
  root: `${SLIDER_INPUT_LABEL_DECORATOR_CLASS_PREFIX}-root`,
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
  const content = '""';

  let rootTop = '0';
  let labelGapMargin = '0 .6em 0 .4em';
  let borderWidth = '1px 0 0 0';
  let opacity = '0.3';

  if (isFocused) {
    rootTop = '-1px';
    labelGapMargin = '0 1em 0 1em';
    borderWidth = '2px 0 0 0';
    opacity = '1';
  }

  return (
    <Box
      className={SLIDER_INPUT_LABEL_DECORATOR_CLASSES.root}
      sx={{
        display: 'flex',
        flexDirection: 'row',
        position: 'absolute',
        top: rootTop,
        width: 'calc(100% - 6px)',

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
          margin: labelGapMargin,
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
  key,
  isFocused,
  ...inputRestProps
}: OutlinedInputProps & {
  key: string;
  isFocused?: boolean;
}) => (
  <OutlinedInput
    // eslint-disable-next-line react/jsx-props-no-spreading
    {...{
      key,
      className: isFocused ? muiOutlinedInputClasses.focused : '',
      type: 'number',
      ...inputRestProps,
    }}
  />
);

const stringToNumber = (value: string, fallback: number) => {
  const converted = Number.parseFloat(value);
  return Number.isNaN(converted) ? fallback : converted;
};

const toRangeString = (value: SliderValue) =>
  value instanceof Array
    ? value.map((element) => String(element))
    : [String(value)];

const toSliderValue = (rangeString: string[], value: SliderValue) =>
  value instanceof Array
    ? rangeString.map((element, index) => stringToNumber(element, value[index]))
    : stringToNumber(rangeString[0], value);

const Slider = ({
  messageBoxProps = SLIDER_DEFAULT_PROPS.messageBoxProps,
  isAllowTextInput = SLIDER_DEFAULT_PROPS.isAllowTextInput,
  label,
  labelId = SLIDER_DEFAULT_PROPS.labelId,
  inputLabelProps = SLIDER_DEFAULT_PROPS.inputLabelProps,
  sliderProps = SLIDER_DEFAULT_PROPS.sliderProps,
  value,
}: SliderProps): JSX.Element => {
  const {
    max,
    min,
    onChange: sliderChangeCallback,
    sx: sliderSx,
    valueLabelDisplay: sliderValueLabelDisplay,
  } = sliderProps;
  let assignableValue: SliderValue = value;

  const [textRangeValue, SetTextRangeValue] = useState<{ range: string[] }>({
    range: toRangeString(value),
  });

  const [isFocused, setIsFocused] = useState<boolean>(false);

  const handleLocalSliderBlur: SliderOnBlur = () => {
    setIsFocused(false);
  };

  const handleLocalSliderFocus: SliderOnFocus = () => {
    setIsFocused(true);
  };

  const handleSliderChange: SliderOnChange = (event, newValue) => {
    SetTextRangeValue({
      range: toRangeString(newValue),
    });

    sliderChangeCallback?.call(null, newValue);
  };

  const handleTextInputChange: TextInputOnChange = () => {
    assignableValue = toSliderValue(textRangeValue.range, assignableValue);

    sliderChangeCallback?.call(null, assignableValue);
  };

  return (
    <FormControl
      sx={{
        display: 'flex',
        flexDirection: 'column',

        '&:hover': {
          [`& .${SLIDER_INPUT_LABEL_DECORATOR_CLASSES.root} div`]: {
            opacity: 1,
          },

          [`& .${muiOutlinedInputClasses.notchedOutline}`]: {
            borderColor: GREY,
          },
        },
      }}
    >
      <OutlinedInputLabel
        // eslint-disable-next-line react/jsx-props-no-spreading
        {...{
          className: isFocused ? muiInputLabelClasses.focused : '',
          id: labelId,
          shrink: true,
          ...inputLabelProps,
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
            value: assignableValue,
            valueLabelDisplay: sliderValueLabelDisplay,
          }}
        />
        {textRangeValue.range.map((textValue, textValueIndex) =>
          createOutlinedInput({
            key: `slider-nested-text-input-${textValueIndex}`,
            inputProps: { max, min },
            isFocused,
            onBlur: handleLocalSliderBlur,
            onChange: (...args) => {
              textRangeValue.range[textValueIndex] = args[0].target.value;
              SetTextRangeValue({ ...textRangeValue });

              handleTextInputChange(...args);
            },
            onFocus: handleLocalSliderFocus,
            sx: isAllowTextInput
              ? undefined
              : {
                  visibility: 'collapse',
                },
            value: textValue,
          }),
        )}
      </Box>
      {/* eslint-disable-next-line react/jsx-props-no-spreading */}
      <InputMessageBox {...messageBoxProps} />
    </FormControl>
  );
};

Slider.defaultProps = SLIDER_DEFAULT_PROPS;

export type { SliderProps };

export default Slider;
