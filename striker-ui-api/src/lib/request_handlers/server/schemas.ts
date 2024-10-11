import * as yup from 'yup';

import { yupLaxUuid } from '../../yupPreSchemas';

export const serverUpdateParamsDictionarySchema = yup.object({
  uuid: yupLaxUuid().required(),
});

export const serverRenameRequestBodySchema = yup.object({
  newName: yup.string().required(),
});
