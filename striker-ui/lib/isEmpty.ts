type IsEmptyTypeMap = Pick<MapToType, 'number' | 'string' | 'undefined'>;

type MapToValueIsEmptyFunction = {
  [TypeName in keyof IsEmptyTypeMap]: (
    value: IsEmptyTypeMap[TypeName],
  ) => boolean;
};

const MAP_TO_VALUE_IS_EMPTY_FUNCTION: MapToValueIsEmptyFunction = {
  number: (value = 0) => value === 0,
  string: (value = '') => value.trim().length === 0,
  undefined: () => true,
};

const isEmpty = <TypeName extends keyof IsEmptyTypeMap>(
  values: Array<IsEmptyTypeMap[TypeName]>,
  { not, fn = 'every' }: { not?: boolean; fn?: 'every' | 'some' } = {},
): boolean =>
  values[fn]((value) => {
    const type = typeof value as TypeName;

    let result = MAP_TO_VALUE_IS_EMPTY_FUNCTION[type](value);

    if (not) {
      result = !result;
    }

    return result;
  });

export default isEmpty;
