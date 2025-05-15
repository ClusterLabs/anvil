import * as yup from 'yup';

import { yupLvmUuid } from '../../../yupCommons';

export const serverSetProtectRequestBodySchema = yup.object({
  lvmVgUuid: yupLvmUuid().when(['operation'], (values, schema) => {
    const [operation] = values;

    if (operation === 'protect') {
      return schema.required();
    }

    return schema;
  }),
  operation: yup
    .string()
    .required()
    .oneOf(['connect', 'disconnect', 'protect', 'remove', 'update']),
  protocol: yup
    .string()
    .oneOf(['long-throw', 'short-throw', 'sync'])
    .default('sync'),
});
