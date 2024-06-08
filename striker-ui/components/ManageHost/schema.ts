import * as yup from 'yup';

import { yupIpv4, yupLaxUuid } from '../../lib/yupMatches';

const schema = yup.object().shape(
  {
    enterpriseKey: yupLaxUuid().optional(),
    ip: yupIpv4().required(),
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
    type: yup.string().oneOf(['dr', 'subnode']).required(),
    uuid: yupLaxUuid().required(),
  },
  [['redhatUsername', 'redhatPassword']],
);

export default schema;
