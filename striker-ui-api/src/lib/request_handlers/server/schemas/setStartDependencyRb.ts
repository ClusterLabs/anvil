import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverSetStartDependencyRequestBodySchema = yup.object({
  active: yup.bool(),
  after: yupLaxUuid(),
  delay: yup.number(),
});
