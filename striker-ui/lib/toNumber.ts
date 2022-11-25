const toNumber: (
  value: unknown,
  parser?: 'parseFloat' | 'parseInt',
) => number = (value, parser = 'parseInt') =>
  typeof value === 'number' ? value : Number[parser](String(value));

export default toNumber;
