import * as yup from 'yup';

import { yupLaxUuid } from '../../lib/yupCommons';

export const requestTargetIdSchema = yup.object({
  uuid: yupLaxUuid().required(),
});
