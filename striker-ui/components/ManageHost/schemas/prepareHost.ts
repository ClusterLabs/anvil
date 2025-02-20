import * as yup from 'yup';

import { yupLaxUuid } from '../../../lib/yupCommons';

const prepareHostSchema = yup.object().shape(
  {
    enterpriseKey: yupLaxUuid().optional(),
    name: yup.string().required(),
    redhatConfirmPassword: yup
      .string()
      .when('redhatPassword', (redhatPassword, field) =>
        String(redhatPassword).length > 0
          ? field.required().oneOf([yup.ref('redhatPassword')])
          : field.optional(),
      ),
    redhatPassword: yup
      .string()
      .when('redhatUsername', (redhatUsername, field) =>
        String(redhatUsername).length > 0 ? field.required() : field.optional(),
      ),
    redhatUsername: yup
      .string()
      .when('redhatPassword', (redhatPassword, field) =>
        String(redhatPassword).length > 0 ? field.required() : field.optional(),
      ),
    target: yup.string().required(),
    type: yup.string().oneOf(['dr', 'subnode']).required(),
    uuid: yupLaxUuid().required(),
  },
  [['redhatUsername', 'redhatPassword']],
);

export default prepareHostSchema;
