import * as yup from 'yup';

import { sanitizeSQLParam } from '../../../sanitizeSQLParam';

export const getJobQueryStringSchema = yup.object({
  command: yup
    .array()
    .of(
      yup
        .string()
        .required()
        .transform((value) => sanitizeSQLParam(value)),
    )
    .ensure(),
  name: yup
    .array()
    .of(
      yup
        .string()
        .required()
        .transform((value) => sanitizeSQLParam(value)),
    )
    .ensure(),
  start: yup.number().default(-1),
});
