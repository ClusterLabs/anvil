import * as yup from 'yup';

export const serverSetCpuRequestBodySchema = yup.object({
  cores: yup.number().required().min(1),
  sockets: yup.number().required().min(1),
});
