import * as yup from 'yup';

export const serverSetBootOrderRequestBodySchema = yup.object({
  order: yup.array(yup.string().required()).required(),
});
