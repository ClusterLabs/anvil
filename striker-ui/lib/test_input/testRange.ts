/**
 * @deprecated
 */
const testRange: (args: MinimalInputTestArgs) => boolean = ({
  max,
  min,
  value,
}) => (value ? value >= min && value <= max : false);

export default testRange;
