import * as yup from 'yup';

const buildDeleteSchema = (detail: APIServerDetail) =>
  yup.object({
    name: yup.string().required().oneOf([detail.name]),
  });

export default buildDeleteSchema;
