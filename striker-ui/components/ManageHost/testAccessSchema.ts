import * as yup from 'yup';

import { yupIpv4 } from '../../lib/yupCommons';

const schema = yup.object({
  ip: yupIpv4().required(),
  password: yup.string().required(),
});

export default schema;
