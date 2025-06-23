import * as yup from 'yup';

import {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_ID_UPS_TYPE,
} from '../inputIds';

import { yupIpv4 } from '../../../lib/yupCommons';

const buildUpsSchema = (template: APIUpsTemplate) => {
  const ids = Object.keys(template);

  return yup.object({
    [INPUT_ID_UPS_IP]: yupIpv4().required(),
    [INPUT_ID_UPS_NAME]: yup.string().required(),
    [INPUT_ID_UPS_TYPE]: yup.string().required().oneOf(ids),
  });
};

type UpsFormikValues = yup.InferType<ReturnType<typeof buildUpsSchema>>;

export type { UpsFormikValues };

export default buildUpsSchema;
