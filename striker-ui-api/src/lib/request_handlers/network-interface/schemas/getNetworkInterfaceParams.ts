import * as yup from 'yup';

import { sanitizeSQLParam } from '../../../sanitizeSQLParam';
import { LOCAL } from '../../../consts';

export const getNetworkInterfaceParamsSchema = yup.object({
  host: yup
    .string()
    .default(LOCAL)
    .transform((value) => sanitizeSQLParam(value)),
});
