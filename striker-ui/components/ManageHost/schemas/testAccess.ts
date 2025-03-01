import * as yup from 'yup';

const testAccessSchema = yup.object({
  password: yup.string().required(),
  target: yup.string().required(),
});

export default testAccessSchema;
