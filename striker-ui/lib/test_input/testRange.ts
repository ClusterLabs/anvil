import { InputTestArgs } from '../../types/TestInputFunction';

const testRange: (args: InputTestArgs) => boolean = ({ max, min, value }) =>
  value ? value >= min && value <= max : false;

export default testRange;
