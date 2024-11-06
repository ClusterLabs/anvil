import * as yup from 'yup';

import { yupLaxMac } from '../../../yupCommons';

export const serverSetIfaceStateRequestBodySchema = yup.object({
  active: yup.bool().required(),
  mac: yupLaxMac().required(),
});
