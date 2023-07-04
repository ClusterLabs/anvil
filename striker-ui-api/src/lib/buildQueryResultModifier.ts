export const buildQueryResultModifier =
  <T>(mod: (output: string[][]) => T): QueryResultModifierFunction =>
  (output) =>
    output instanceof Array ? mod(output) : output;

export const buildQueryResultReducer = <T>(
  reduce: (previous: T, row: string[]) => T,
  initialValue: T,
) =>
  buildQueryResultModifier<T>((output) =>
    output.reduce<T>(reduce, initialValue),
  );
