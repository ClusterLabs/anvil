import * as yup from 'yup';

const buildYupDynamicObject = <S extends yup.Schema>(
  obj: yup.AnyObject,
  schema: S,
): Record<string, S> =>
  Object.keys(obj).reduce<Record<string, S>>(
    (previous, key) => ({
      ...previous,
      [key]: schema,
    }),
    {},
  );

export default buildYupDynamicObject;
