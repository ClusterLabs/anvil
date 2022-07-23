import { Dispatch, SetStateAction } from 'react';

import { InputProps as MUIInputProps } from '@mui/material';

export type MapToStateSetter = {
  [TypeName in keyof MapToType]: Dispatch<SetStateAction<MapToType[TypeName]>>;
};

export type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};

export type InputOnChangeParameters = Parameters<
  Exclude<MUIInputProps['onChange'], undefined>
>;

const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
};

const createInputOnChangeHandler =
  <TypeName extends keyof MapToType>({
    postSet,
    preSet,
    set,
    setType = 'string',
  }: {
    postSet?: (...args: InputOnChangeParameters) => void;
    preSet?: (...args: InputOnChangeParameters) => void;
    set?: MapToStateSetter[TypeName];
    setType?: TypeName | 'string';
  } = {}): MUIInputProps['onChange'] =>
  (event) => {
    const {
      target: { value },
    } = event;
    const postConvertValue = MAP_TO_VALUE_CONVERTER[setType](
      value,
    ) as MapToType[TypeName];

    preSet?.call(null, event);
    set?.call(null, postConvertValue);
    postSet?.call(null, event);
  };

export default createInputOnChangeHandler;
