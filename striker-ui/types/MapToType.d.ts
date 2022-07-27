declare type MapToType = {
  number: number;
  string: string;
  undefined: undefined;
};

declare type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};
