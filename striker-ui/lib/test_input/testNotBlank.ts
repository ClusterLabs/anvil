import { InputTestArgs } from '../../types/TestInputFunction';

const testNotBlank: (args: InputTestArgs) => boolean = ({ value }) =>
  value !== '';

export default testNotBlank;
