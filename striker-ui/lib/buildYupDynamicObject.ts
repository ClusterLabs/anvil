import * as yup from 'yup';

const buildYupDynamicObject = <S extends yup.Schema>(
  obj: yup.AnyObject,
  schema: S | ((key: string, value: unknown) => S),
): Record<string, S> => {
  let keys: string[];

  try {
    keys = Object.keys(obj);
  } catch (error) {
    keys = [];
  }

  const getSchema = typeof schema === 'function' ? schema : () => schema;

  return keys.reduce<Record<string, S>>((previous, key) => {
    const { [key]: value } = obj;

    previous[key] = getSchema(key, value);

    return previous;
  }, {});
};

export default buildYupDynamicObject;
