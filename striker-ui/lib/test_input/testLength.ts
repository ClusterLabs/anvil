/**
 * @deprecated
 */
const testLength: (
  args: Pick<MinimalInputTestArgs, 'value'> &
    Partial<Pick<MinimalInputTestArgs, 'max' | 'min'>>,
) => boolean = ({ max, min, value }) => {
  const { length } = String(value);

  let isGEMin = true;
  let isLEMax = true;

  if (min) {
    isGEMin = length >= min;
  }

  if (max) {
    isLEMax = length <= max;
  }

  return isGEMin && isLEMax;
};

export default testLength;
