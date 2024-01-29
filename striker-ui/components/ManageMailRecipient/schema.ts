import * as yup from 'yup';

import buildYupDynamicObject from '../../lib/buildYupDynamicObject';

const alertLevelSchema = yup.number().oneOf([0, 1, 2, 3, 4]);

const alertOverrideSchema = yup.object({
  delete: yup.boolean().optional(),
  level: alertLevelSchema.required(),
  target: yup.object({
    type: yup.string().oneOf(['node', 'subnode']).required(),
    uuid: yup.string().uuid().required(),
  }),
  uuid: yup.string().uuid().optional(),
});

const alertOverrideListSchema = yup.lazy((entries) =>
  yup.object(buildYupDynamicObject(entries, alertOverrideSchema)),
);

const mailRecipientSchema = yup.object({
  alertOverrides: alertOverrideListSchema,
  email: yup.string().email().required(),
  language: yup.string().oneOf(['en_CA']).optional(),
  level: alertLevelSchema.required(),
  name: yup.string().required(),
  uuid: yup.string().uuid().optional(),
});

const mailRecipientListSchema = yup.lazy((entries) =>
  yup.object(buildYupDynamicObject(entries, mailRecipientSchema)),
);

export default mailRecipientListSchema;
