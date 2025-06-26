import * as yup from 'yup';

import buildManifestHostFenceSchema from './buildManifestHostFenceSchema';
import buildManifestHostNetworkSchema from './buildManifestHostNetworkSchema';
import buildManifestHostUpsSchema from './buildManifestHostUpsSchema';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';
import { yupIpv4 } from '../../../lib/yupCommons';

import { INPUT_ID_AH_IPMI_IP } from '../inputIds';

const buildManifestHostSchema = () =>
  yup.object({
    [INPUT_ID_AH_IPMI_IP]: yupIpv4().required(),
    fences: yup.lazy((obj) =>
      yup.object(buildYupDynamicObject(obj, buildManifestHostFenceSchema())),
    ),
    networks: yup.lazy((obj) =>
      yup.object(buildYupDynamicObject(obj, buildManifestHostNetworkSchema())),
    ),
    upses: yup.lazy((obj) =>
      yup.object(buildYupDynamicObject(obj, buildManifestHostUpsSchema())),
    ),
  });

export default buildManifestHostSchema;
