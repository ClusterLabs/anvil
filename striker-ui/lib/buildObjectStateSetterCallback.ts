const buildObjectStateSetterCallback =
  <S extends Record<string, unknown>>(key: keyof S, value: S[keyof S]) =>
  ({ [key]: toReplace, ...restPrevious }: S): S =>
    ({
      ...restPrevious,
      [key]: value,
    } as S);

export default buildObjectStateSetterCallback;
