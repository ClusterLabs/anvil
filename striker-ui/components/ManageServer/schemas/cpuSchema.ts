import * as yup from 'yup';

const cpuSchema = yup.object({
  cores: yup.number().min(1).required(),
  sockets: yup.number().min(1).required(),
});

export default cpuSchema;
