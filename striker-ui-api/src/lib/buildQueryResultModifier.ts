type QueryField = string;

export const buildQueryResultModifier =
  <T>(mod: (output: QueryField[][]) => T): QueryResultModifierFunction =>
  (output) =>
    output instanceof Array ? mod(output) : output;

export const buildQueryResultReducer = <T>(
  reduce: (previous: T, row: QueryField[]) => T,
  initialValue: T,
) =>
  buildQueryResultModifier<T>((output) =>
    output.reduce<T>(reduce, initialValue),
  );
