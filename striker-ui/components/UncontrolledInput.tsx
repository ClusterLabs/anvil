import {
  InputProps as MuiInputProps,
  SwitchProps as MuiSwitchProps,
} from '@mui/material';
import {
  ForwardedRef,
  cloneElement,
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useState,
} from 'react';

import INPUT_TYPES from '../lib/consts/INPUT_TYPES';
import MAP_TO_VALUE_CONVERTER from '../lib/consts/MAP_TO_VALUE_CONVERTER';

const UncontrolledInput = forwardRef(
  <
    ValueType extends keyof MapToInputType,
    InputElement extends React.ReactElement<
      MuiInputProps & Pick<MuiSwitchProps, 'checked'>
    >,
  >(
    props: UncontrolledInputProps<InputElement>,
    ref: ForwardedRef<UncontrolledInputForwardedRefContent<ValueType>>,
  ) => {
    const {
      input,
      onChange = ({ handlers: { base, origin } }, ...args) => {
        base?.call(null, ...args);
        origin?.call(null, ...args);
      },
      onMount,
      onUnmount,
    } = props;
    const { props: inputProps } = input;

    const { valueKey, valueType } = useMemo(() => {
      const { type } = inputProps;

      let vkey: 'checked' | 'value' = 'value';
      let vtype: keyof MapToInputType = 'string';

      if (type === INPUT_TYPES.checkbox) {
        vkey = 'checked';
        vtype = 'boolean';
      }

      return {
        valueKey: vkey,
        valueType: vtype,
      };
    }, [inputProps]);

    const {
      onChange: inputOnChange,
      [valueKey]: unknownValue,
      ...restInputProps
    } = inputProps;

    const originalValue = unknownValue as MapToInputType[ValueType];

    const [value, setValue] =
      useState<MapToInputType[ValueType]>(originalValue);

    const baseChangeEventHandler = useCallback<
      React.ChangeEventHandler<HTMLInputElement>
    >(
      ({ target: { [valueKey]: changed } }) => {
        const converted = MAP_TO_VALUE_CONVERTER[valueType](
          changed,
        ) as MapToInputType[ValueType];

        setValue(converted);
      },
      [valueKey, valueType],
    );

    const changeEventHandler = useCallback<
      React.ChangeEventHandler<HTMLInputElement>
    >(
      (...args) =>
        onChange?.call(
          null,
          { handlers: { base: baseChangeEventHandler, origin: inputOnChange } },
          ...args,
        ),
      [baseChangeEventHandler, inputOnChange, onChange],
    );

    // Handle mount/unmount events; these only happen once hence no deps
    useEffect(() => {
      onMount?.call(null);

      return onUnmount;

      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    // Always update the input's local value when the origin changes
    useEffect(() => {
      setValue(originalValue);
    }, [originalValue]);

    useImperativeHandle(
      ref,
      () => ({
        get: () => value,
        set: setValue,
      }),
      [value],
    );

    return cloneElement(input, {
      ...restInputProps,
      onChange: changeEventHandler,
      [valueKey]: value,
    });
  },
);

UncontrolledInput.displayName = 'UncontrolledInput';

export default UncontrolledInput;
