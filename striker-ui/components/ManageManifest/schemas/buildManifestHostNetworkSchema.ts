import * as yup from 'yup';

import { yupIpv4 } from '../../../lib/yupCommons';

import { INPUT_ID_AH_NETWORK_IP } from '../inputIds';

const buildManifestHostNetworkSchema = () =>
  yup.object({
    [INPUT_ID_AH_NETWORK_IP]: yupIpv4().required(),
  });

export default buildManifestHostNetworkSchema;
