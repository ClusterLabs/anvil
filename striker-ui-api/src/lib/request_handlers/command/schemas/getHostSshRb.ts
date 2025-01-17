import * as yup from 'yup';

import { yupIpv4 } from '../../../yupCommons';

export const getHostSshRequestBodySchema = yup.object({
  password: yup.string().required(),
  port: yup.number().default(22).min(0),
  ipAddress: yupIpv4().required(),
});
