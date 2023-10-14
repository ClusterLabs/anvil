const buildYupDynamicObject = <S>(
  obj: Record<string, S> | undefined,
  schema: S,
): Record<string, S> | undefined =>
  obj &&
  Object.keys(obj).reduce<Record<string, S>>(
    (previous, key) => ({
      ...previous,
      [key]: schema,
    }),
    {},
  );

export default buildYupDynamicObject;
