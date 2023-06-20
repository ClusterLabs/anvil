/**
 * Checks whether specified `key` is unset in given object. Always returns
 * `true` when overwrite is allowed.
 */
const checkUnset = <S extends BaseObject>(
  obj: S,
  key: keyof S,
  { isOverwrite = false }: { isOverwrite?: boolean } = {},
): boolean => !(key in obj) || isOverwrite;

const defaultObjectStatePropSetter = <S extends BaseObject>(
  ...[, result, key, value]: Parameters<ObjectStatePropSetter<S>>
): ReturnType<ObjectStatePropSetter<S>> => {
  if (value !== undefined) {
    result[key] = value;
  }
};

const buildObjectStateSetterCallback =
  <S extends BaseObject>(
    key: keyof S,
    value?: S[keyof S],
    {
      guard = () => true,
      set = defaultObjectStatePropSetter,
    }: BuildObjectStateSetterCallbackOptions<S> = {},
  ): BuildObjectStateSetterCallbackReturnType<S> =>
  (previous: S): S => {
    const { [key]: toReplace, ...restPrevious } = previous;
    const result = { ...restPrevious } as S;

    if (guard(previous, key, value)) {
      set(previous, result, key, value);
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

export const buildRegExpObjectStateSetterCallback =
  <S extends BaseObject>(
    re: RegExp,
    value?: S[keyof S],
    {
      set = defaultObjectStatePropSetter,
    }: Pick<BuildObjectStateSetterCallbackOptions<S>, 'set'> = {},
  ) =>
  (previous: S): S => {
    const result: S = {} as S;

    Object.keys(previous).forEach((key) => {
      const k = key as keyof S;

      if (re.test(key)) {
        set(previous, result, k, value);
      } else {
        result[k] = previous[k];
      }
    });

    return result;
  };

export default buildObjectStateSetterCallback;
