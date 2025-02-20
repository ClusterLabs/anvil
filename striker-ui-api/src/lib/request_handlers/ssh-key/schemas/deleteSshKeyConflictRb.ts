import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

const keySchema = yup.string().required();

const hostSchema = yup.object({
  uuid: yupLaxUuid(),
});

export const deleteSshKeyConflictRequestBodySchema = yup.object({
  badKeys: yup.array(keySchema).required(),
  badHost: hostSchema,
});
