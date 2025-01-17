import * as yup from 'yup';

export const deleteSshKeyConflictRequestBodySchema = yup.object({
  badKeys: yup.array(yup.string().required()).required(),
});
