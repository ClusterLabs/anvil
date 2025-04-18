import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const getHostQueryStringSchema = yup.object({
  node: yup.array().of(yupLaxUuid().required()).ensure(),
  type: yup
    .array()
    .of(
      yup
        .string()
        .required()
        // Transforms run before validation!
        .transform((value) => (value === 'subnode' ? 'node' : value))
        .oneOf(['dr', 'node', 'striker']),
    )
    .ensure(),
});
