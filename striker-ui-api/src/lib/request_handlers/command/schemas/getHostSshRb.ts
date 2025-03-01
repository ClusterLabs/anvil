import * as yup from 'yup';

export const getHostSshRequestBodySchema = yup.object({
  password: yup.string().required(),
  port: yup.number().default(22).min(0),
  target: yup.string().required(),
});
