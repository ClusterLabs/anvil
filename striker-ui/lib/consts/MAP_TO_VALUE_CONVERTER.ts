const MAP_TO_VALUE_CONVERTER: MapToValueConverter = {
  boolean: (value) => Boolean(value),
  number: (value) => parseInt(String(value), 10) || 0,
  string: (value) => String(value),
};

export default MAP_TO_VALUE_CONVERTER;
