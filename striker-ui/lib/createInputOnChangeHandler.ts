import { InputProps as MUIInputProps } from '@mui/material';

import MAP_TO_VALUE_CONVERTER from './consts/MAP_TO_VALUE_CONVERTER';

const createInputOnChangeHandler =
  <TypeName extends keyof MapToInputType>({
    postSet,
    preSet,
    set,
    setType = 'string' as TypeName,
  }: CreateInputOnChangeHandlerOptions<TypeName> = {}): MUIInputProps['onChange'] =>
  (event) => {
    const {
      target: { value },
    } = event;
    const postConvertValue = MAP_TO_VALUE_CONVERTER[setType](
      value,
    ) as MapToInputType[TypeName];

    preSet?.call(null, event);
    set?.call(null, postConvertValue);
    postSet?.call(null, event);
  };

export default createInputOnChangeHandler;
