type NestedObject<T> = {
  [key: number | string]: NestedObject<T> | T;
};

export const traverse = <T, O extends NestedObject<V>, V = unknown>(
  obj: O,
  init: T,
  onKey: (previous: T, obj: O, key: string) => { is: boolean; next: O },
  {
    onEnd,
    previous = init,
  }: {
    onEnd?: (previous: T, obj: O, key: string) => void;
    previous?: T;
  } = {},
) => {
  Object.keys(obj).forEach((key: string) => {
    const { is: proceed, next } = onKey(previous, obj, key);

    if (proceed) {
      traverse(next, init, onKey, { previous });
    } else {
      onEnd?.call(null, previous, obj, key);
    }
  });

  return previous;
};
