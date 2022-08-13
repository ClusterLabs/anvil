const getFilled = <T>(
  array: T[],
  { isReverse = false }: { isReverse?: boolean } = {},
): T[] =>
  array.filter(
    isReverse
      ? (element: T) => element === undefined
      : (element: T) => element !== undefined,
  );

export default getFilled;
