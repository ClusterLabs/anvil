type SelectItem<
  ValueType = string,
  DisplayValueType = ValueType | import('react').ReactNode,
> = {
  displayValue?: DisplayValueType;
  value: ValueType;
};
