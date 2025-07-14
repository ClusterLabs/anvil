import * as yup from 'yup';

import { yupLaxUuid } from '../../../yupCommons';

export const getServerQueryStringSchema = yup.object({
  anvilUUIDs: yup.array().of(yupLaxUuid().required()).ensure(),
});

type ServerQs = yup.InferType<typeof getServerQueryStringSchema>;

export type { ServerQs };
