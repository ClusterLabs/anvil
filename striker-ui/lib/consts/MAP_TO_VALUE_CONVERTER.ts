const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
  undefined: () => undefined,
};

export default MAP_TO_VALUE_CONVERTER;
