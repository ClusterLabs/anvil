import * as yup from 'yup';

const buildCpuCoresSchema = (max: number) =>
  yup.number().min(1).max(max).required();

export default buildCpuCoresSchema;
