export const setChain = <T extends boolean | number | string>(
  chain: string[],
  value: T | Tree<T>,
  parent: Tree<T> = {},
): T | Tree<T> => {
  const { 0: key, length } = chain;

  if (!key) {
    return parent;
  }

  const { [key]: existing } = parent;

  if (
    length > 1 &&
    (existing === undefined ||
      (typeof existing === 'object' && existing !== null))
  ) {
    parent[key] = setChain(chain.slice(1), value, existing);
  } else {
    parent[key] = value;
  }

  return parent;
};
