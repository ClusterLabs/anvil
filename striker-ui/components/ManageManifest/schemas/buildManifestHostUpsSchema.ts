import * as yup from 'yup';

import { INPUT_ID_AH_UPS_POWER_HOST } from '../inputIds';

const buildManifestHostUpsSchema = () =>
  yup.object({
    [INPUT_ID_AH_UPS_POWER_HOST]: yup.boolean().required(),
  });

export default buildManifestHostUpsSchema;
