import { InputTestArgs } from '../../types/TestInputFunction';

const testNotBlank: (args: InputTestArgs) => boolean = ({ value }) =>
  value ? String(value).length > 0 : false;

export default testNotBlank;
