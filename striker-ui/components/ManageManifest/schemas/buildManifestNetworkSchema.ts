import * as yup from 'yup';

import { yupIpv4 } from '../../../lib/yupCommons';

import {
  INPUT_ID_AN_GATEWAY,
  INPUT_ID_AN_MIN_IP,
  INPUT_ID_AN_NETWORK_NUMBER,
  INPUT_ID_AN_NETWORK_TYPE,
  INPUT_ID_AN_SUBNET_MASK,
} from '../inputIds';

const buildManifestNetworkSchema = () =>
  yup.object({
    [INPUT_ID_AN_GATEWAY]: yupIpv4(),
    [INPUT_ID_AN_MIN_IP]: yupIpv4(),
    [INPUT_ID_AN_NETWORK_TYPE]: yup.string().oneOf(['bcn', 'ifn', 'mn', 'sn']),
    [INPUT_ID_AN_NETWORK_NUMBER]: yup.number().min(1),
    [INPUT_ID_AN_SUBNET_MASK]: yupIpv4(),
  });

export default buildManifestNetworkSchema;
