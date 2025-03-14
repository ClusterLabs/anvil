import * as yup from 'yup';

import { yupLaxUuid } from '../../lib/yupCommons';

export const requestTargetSchema = yup.object({
  uuid: yupLaxUuid().required(),
});
