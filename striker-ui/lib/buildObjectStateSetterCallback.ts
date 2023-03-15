const buildObjectStateSetterCallback =
  <S extends Record<string, unknown>>(key: keyof S, value?: S[keyof S]) =>
  ({ [key]: toReplace, ...restPrevious }: S): S => {
    const result = { ...restPrevious } as S;

    if (value !== undefined) {
      result[key] = value;
    }

    return result;
  };

export default buildObjectStateSetterCallback;
