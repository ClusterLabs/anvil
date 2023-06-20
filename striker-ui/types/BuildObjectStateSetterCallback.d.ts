type BaseObject<T = unknown> = Record<number | string | symbol, T>;

type ObjectStatePropGuard<S extends BaseObject> = (
  previous: S,
  key: keyof S,
  value?: S[keyof S],
) => boolean;

type ObjectStatePropSetter<S extends BaseObject> = (
  previous: S,
  result: S,
  key: keyof S,
  value?: S[keyof S],
) => void;

type BuildObjectStateSetterCallbackOptions<S extends BaseObject> = {
  guard?: ObjectStatePropGuard<S>;
  isOverwrite?: boolean;
  set?: ObjectStatePropSetter<S>;
};

type BuildObjectStateSetterCallbackReturnType<S extends BaseObject> = (
  previous: S,
) => S;
