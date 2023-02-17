import { ChangeEventHandler } from 'react';

import MAP_TO_VALUE_CONVERTER from './consts/MAP_TO_VALUE_CONVERTER';

const createInputOnChangeHandler =
  <TypeName extends keyof MapToInputType>({
    postSet,
    preSet,
    set,
    setType = 'string' as TypeName,
    valueKey = 'value',
  }: CreateInputOnChangeHandlerOptions<TypeName> = {}): ChangeEventHandler<HTMLInputElement> =>
  (event) => {
    const {
      target: { [valueKey]: value },
    } = event;
    const postConvertValue = MAP_TO_VALUE_CONVERTER[setType](
      value,
    ) as MapToInputType[TypeName];

    preSet?.call(null, event);
    set?.call(null, postConvertValue);
    postSet?.call(null, event);
  };

export default createInputOnChangeHandler;
