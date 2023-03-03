type MapToMessageSetter<T extends MapToInputTestID> = {
  [MessageSetterID in keyof T]: MessageSetterFunction;
};

type InputIds<T> = ReadonlyArray<T> | MapToInputTestID;

/**
 * Given either:
 *   1. an array of input identifiers, or
 *   2. a key-value object of input indentifiers,
 * transform it into a key-value object of identifiers.
 */
type MapToInputId<
  U extends string,
  I extends InputIds<U>,
> = I extends ReadonlyArray<U> ? { [K in I[number]]: K } : I;
