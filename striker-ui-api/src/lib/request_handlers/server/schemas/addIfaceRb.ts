import * as yup from 'yup';

import { yupLaxMac } from '../../../yupCommons';

export const serverAddIfaceRequestBodySchema = yup.object({
  bridge: yup.string().required(),
  mac: yupLaxMac(),
  model: yup.string(),
});
