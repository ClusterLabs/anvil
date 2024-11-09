import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const serverUpdateParamsDictionarySchema = yup.object({
  uuid: yupLaxUuid().required(),
});
