import * as yup from 'yup';

export const serverMigrateRequestBodySchema = yup.object({
  target: yup.string().required(),
});
