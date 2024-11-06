import * as yup from 'yup';

export const serverRenameRequestBodySchema = yup.object({
  name: yup.string().required(),
});
