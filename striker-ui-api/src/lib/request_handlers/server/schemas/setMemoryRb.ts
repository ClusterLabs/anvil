import * as yup from 'yup';

export const serverSetMemoryRequestBodySchema = yup.object({
  size: yup.string().required(),
});
