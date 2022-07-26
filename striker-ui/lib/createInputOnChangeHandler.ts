import { InputProps as MUIInputProps } from '@mui/material';
import { Dispatch, SetStateAction } from 'react';

import MAP_TO_VALUE_CONVERTER from './consts/MAP_TO_VALUE_CONVERTER';

type InputOnChangeParameters = Parameters<
  Exclude<MUIInputProps['onChange'], undefined>
>;

type MapToStateSetter = {
  [TypeName in keyof MapToType]: Dispatch<SetStateAction<MapToType[TypeName]>>;
};

type CreateInputOnChangeHandlerOptions<TypeName extends keyof MapToType> = {
  postSet?: (...args: InputOnChangeParameters) => void;
  preSet?: (...args: InputOnChangeParameters) => void;
  set?: MapToStateSetter[TypeName];
  setType?: TypeName | 'string';
};

const createInputOnChangeHandler =
  <TypeName extends keyof MapToType>({
    postSet,
    preSet,
    set,
    setType = 'string',
  }: CreateInputOnChangeHandlerOptions<TypeName> = {}): MUIInputProps['onChange'] =>
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

export type {
  CreateInputOnChangeHandlerOptions,
  InputOnChangeParameters,
  MapToStateSetter,
};

export default createInputOnChangeHandler;
