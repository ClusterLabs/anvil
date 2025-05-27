import * as yup from 'yup';

import { LOCAL } from '../../lib/consts';

import { getLocalHostUUID } from '../../lib/accessModule';
import { yupLaxUuid } from '../../lib/yupCommons';

export const requestTargetSchema = yup.object({
  uuid: yupLaxUuid()
    .transform((value) => (value === LOCAL ? getLocalHostUUID() : value))
    .required(),
});
