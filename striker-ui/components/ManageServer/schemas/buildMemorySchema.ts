import * as yup from 'yup';

import { buildMemorySizeSchema } from '../../ProvisionServer';

const buildMemorySchema = (memory: AnvilMemoryCalcable) => {
  const { available: max } = memory;

  return yup.object({
    size: buildMemorySizeSchema(max),
  });
};

export default buildMemorySchema;
