import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverChangeIsoRequestBodySchema = yup.object({
  anvil: yupLaxUuid(),
  device: yup.string().required(),
  iso: yupLaxUuid(),
});
