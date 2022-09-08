declare type MapToType = {
  boolean: boolean;
  number: number;
  string: string;
  undefined: undefined;
};

declare type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};
