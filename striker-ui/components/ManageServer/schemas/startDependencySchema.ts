import * as yup from 'yup';

const startDependencySchema = yup.object({
  after: yup.string(),
  delay: yup.number().min(0),
});

export default startDependencySchema;
