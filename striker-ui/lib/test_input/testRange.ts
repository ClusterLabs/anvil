import { InputTestArgs } from '../../types/TestInputFunction';

const testRange: (args: InputTestArgs) => boolean = ({ max, min, value }) =>
  value >= min && value <= max;

export default testRange;
