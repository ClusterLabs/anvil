import * as yup from 'yup';

import buildYupDynamicObject from '../../lib/buildYupDynamicObject';
import { yupLaxUuid } from '../../lib/yupCommons';

const mailServerSchema = yup.object({
  address: yup.string().required(),
  authentication: yup.string().oneOf(['none', 'plain-text', 'encrypted']),
  confirmPassword: yup
    .string()
    .when('password', (password, field) =>
      String(password).length > 0
        ? field.required().oneOf([yup.ref('password')])
        : field.optional(),
    ),
  heloDomain: yup.string().required(),
  password: yup.string().optional(),
  port: yup.number().required(),
  security: yup.string().oneOf(['none', 'starttls', 'tls-ssl']),
  username: yup.string().optional(),
  uuid: yupLaxUuid().required(),
});

const mailServerListSchema = yup.lazy((mailServers) =>
  yup.object(buildYupDynamicObject(mailServers, mailServerSchema)),
);

export default mailServerListSchema;
