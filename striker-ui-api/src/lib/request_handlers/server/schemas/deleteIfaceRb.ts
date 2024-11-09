import * as yup from 'yup';

import { yupLaxMac } from '../../../yupCommons';

export const serverDeleteIfaceRequestBodySchema = yup.object({
  mac: yupLaxMac().required(),
});
