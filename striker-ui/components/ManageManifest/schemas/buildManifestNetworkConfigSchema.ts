import * as yup from 'yup';

import buildManifestNetworkSchema from './buildManifestNetworkSchema';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';

import { INPUT_ID_ANC_DNS, INPUT_ID_ANC_NTP } from '../inputIds';

const buildManifestNetworkConfigSchema = () =>
  yup.object({
    [INPUT_ID_ANC_DNS]: yup.string(),
    [INPUT_ID_ANC_NTP]: yup.string(),
    networks: yup.lazy((obj) =>
      yup.object(buildYupDynamicObject(obj, buildManifestNetworkSchema())),
    ),
  });

export default buildManifestNetworkConfigSchema;
