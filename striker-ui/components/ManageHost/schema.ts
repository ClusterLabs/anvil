import * as yup from 'yup';

import { REP_IPV4 } from '../../lib/consts/REG_EXP_PATTERNS';

const schema = yup.object().shape(
  {
    enterpriseKey: yup.string().uuid().optional(),
    ip: yup.string().matches(REP_IPV4, {
      message: 'Expected IP address to be a valid IPv4 address.',
    }),
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
    uuid: yup.string().uuid().required(),
  },
  [['redhatUsername', 'redhatPassword']],
);

export default schema;
