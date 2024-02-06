import * as yup from 'yup';

import { REP_IPV4 } from '../../lib/consts/REG_EXP_PATTERNS';

const schema = yup.object({
  ip: yup
    .string()
    .matches(REP_IPV4, {
      message: 'Expected IP address to be a valid IPv4 address.',
    })
    .required(),
  password: yup.string().required(),
});

export default schema;
