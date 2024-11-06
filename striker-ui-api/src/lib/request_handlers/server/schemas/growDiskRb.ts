import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverGrowDiskRequestBodySchema = yup.object({
  anvil: yupLaxUuid(),
  device: yup.string().required(),
  size: yup.string().required(),
});
