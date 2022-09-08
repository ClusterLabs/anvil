declare type MapToType = {
  boolean: boolean;
  number: number;
  object: Record<string, unknown>;
  string: string;
  undefined: undefined;
};

declare type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};
