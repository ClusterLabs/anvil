const convertFenceParameterToString = (
  value: boolean | number | string,
  type: FenceParameterType,
) => {
  let str: string;

  if (type === 'boolean') {
    str = value ? '1' : '0';
  } else {
    str = String(value);
  }

  return str;
};

export default convertFenceParameterToString;
