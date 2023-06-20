export const isObject = (value: unknown) => {
  const result: { is: boolean; obj: object } = { is: false, obj: {} };

  if (typeof value === 'object' && value !== null) {
    result.is = true;
    result.obj = value;
  }

  return result;
};
