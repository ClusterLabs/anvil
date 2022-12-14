const sumstring = (value: string): number => {
  let sum = 0;

  for (let index = 0; index < value.length; index += 1) {
    sum += value.codePointAt(index) || 0;
  }

  return sum;
};

export default sumstring;
