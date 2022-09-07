import { InputProps as MUIInputProps } from '@mui/material';
import { Dispatch, SetStateAction } from 'react';

import MAP_TO_VALUE_CONVERTER from './consts/MAP_TO_VALUE_CONVERTER';

type CreateInputOnChangeHandlerTypeMap = Pick<MapToType, 'number' | 'string'>;

type InputOnChangeParameters = Parameters<
  Exclude<MUIInputProps['onChange'], undefined>
>;

type MapToStateSetter = {
  [TypeName in keyof CreateInputOnChangeHandlerTypeMap]: Dispatch<
    SetStateAction<CreateInputOnChangeHandlerTypeMap[TypeName]>
  >;
};

type CreateInputOnChangeHandlerOptions<
  TypeName extends keyof CreateInputOnChangeHandlerTypeMap,
> = {
  postSet?: (...args: InputOnChangeParameters) => void;
  preSet?: (...args: InputOnChangeParameters) => void;
  set?: MapToStateSetter[TypeName];
  setType?: TypeName | 'string';
};

const createInputOnChangeHandler =
  <TypeName extends keyof CreateInputOnChangeHandlerTypeMap>({
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
    ) as CreateInputOnChangeHandlerTypeMap[TypeName];

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
