import * as yup from 'yup';

const buildYupDynamicObject = <S extends yup.Schema>(
  obj: yup.AnyObject,
  schema: S,
): Record<string, S> => {
  let keys: string[];

  try {
    keys = Object.keys(obj);
  } catch (error) {
    keys = [];
  }

  return keys.reduce<Record<string, S>>(
    (previous, key) => ({
      ...previous,
      [key]: schema,
    }),
    {},
  );
};

export default buildYupDynamicObject;
