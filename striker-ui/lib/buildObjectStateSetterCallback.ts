/**
 * Checks whether specified `key` is unset in given object. Always returns
 * `true` when overwrite is allowed.
 */
const checkUnset = <S extends BaseObject>(
  obj: S,
  key: keyof S,
  { isOverwrite = false }: { isOverwrite?: boolean } = {},
): boolean => !(key in obj) || isOverwrite;

const buildObjectStateSetterCallback =
  <S extends BaseObject>(
    key: keyof S,
    value?: S[keyof S],
    {
      guard,
      set = (o, k, v) => {
        if (v !== undefined) {
          o[k] = v;
        }
      },
    }: BuildObjectStateSetterCallbackOptions<S> = {},
  ): BuildObjectStateSetterCallbackReturnType<S> =>
  (previous: S): S => {
    const { [key]: toReplace, ...restPrevious } = previous;
    const result = { ...restPrevious } as S;

    if (guard?.call(null, previous, key, value)) {
      set(result, key, value);
    }

    return result;
  };

export const buildProtectedObjectStateSetterCallback = <S extends BaseObject>(
  key: keyof S,
  value?: S[keyof S],
  {
    isOverwrite,
    guard = (o, k) => checkUnset(o, k, { isOverwrite }),
    set,
  }: BuildObjectStateSetterCallbackOptions<S> = {},
): BuildObjectStateSetterCallbackReturnType<S> =>
  buildObjectStateSetterCallback(key, value, { isOverwrite, guard, set });

export default buildObjectStateSetterCallback;
