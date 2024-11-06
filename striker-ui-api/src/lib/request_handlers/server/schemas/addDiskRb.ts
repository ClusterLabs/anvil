import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverAddDiskRequestBodySchema = yup.object({
  anvil: yupLaxUuid(),
  size: yup.string().required(),
  storage: yupLaxUuid(),
});
