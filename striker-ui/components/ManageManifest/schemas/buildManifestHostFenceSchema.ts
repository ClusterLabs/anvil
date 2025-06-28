import * as yup from 'yup';

import { INPUT_ID_AH_FENCE_PORT } from '../inputIds';

const buildManifestHostFenceSchema = () =>
  yup.object({
    [INPUT_ID_AH_FENCE_PORT]: yup.string(),
  });

export default buildManifestHostFenceSchema;
