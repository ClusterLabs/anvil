import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverSetProtectRequestBodySchema = yup.object({
  drUuid: yupLaxUuid().required(),
  protect: yup.boolean(),
  protocol: yup.string().oneOf(['long-throw', 'short-throw', 'sync']),
});
