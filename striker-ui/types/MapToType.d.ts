declare type MapToType = {
  number: number;
  string: string;
};

declare type MapToValueConverter = {
  [TypeName in keyof MapToType]: (value: unknown) => MapToType[TypeName];
};
