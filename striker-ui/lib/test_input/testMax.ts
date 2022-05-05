import { InputTestArgs } from '../../types/TestInputFunction';

const testMax: (args: InputTestArgs) => boolean = ({ max, min }) => max >= min;

export default testMax;
