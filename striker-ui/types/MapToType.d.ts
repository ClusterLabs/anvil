declare type MapToType = {
  boolean: boolean;
  number: number;
  object: Record<string, unknown>;
  string: string;
  undefined: undefined;
};

type ReducedMapToType = Pick<MapToType, 'boolean' | 'number' | 'string'>;

declare type MapToValueConverter = {
  [TypeName in keyof ReducedMapToType]: (
    value: unknown,
  ) => ReducedMapToType[TypeName];
};
