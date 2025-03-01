import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

const enterpriseSchema = yup.object({
  uuid: yupLaxUuid(),
});

const sshSchema = yup.object({
  port: yup.number().default(22).min(0),
});

const hostSchema = yup.object({
  name: yup.string().required(),
  password: yup.string().required(),
  ssh: sshSchema,
  type: yup.string().required().oneOf(['dr', 'node']),
  user: yup.string().default('root'),
  uuid: yupLaxUuid(),
});

const redhatSchema = yup.object().shape(
  {
    password: yup.string().when(['user'], (values, schema) => {
      const [user] = values;

      return user ? schema.required() : schema;
    }),
    user: yup.string().when(['password'], (values, schema) => {
      const [password] = values;

      return password ? schema.required() : schema;
    }),
  },
  [['user', 'password']],
);

export const prepareHostRequestBodySchema = yup.object({
  enterprise: enterpriseSchema,
  host: hostSchema,
  redhat: redhatSchema,
  target: yup.string().required(),
});
