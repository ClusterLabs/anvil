import * as yup from 'yup';

import { REP_IPV4_CSV } from '../../lib/consts/REG_EXP_PATTERNS';

import buildYupDynamicObject from '../../lib/buildYupDynamicObject';
import hostNetSchema from './hostNetSchema';
import { yupIpv4 } from '../../lib/yupMatches';

const hostNetInitSchema = yup.object({
  dns: yup
    .string()
    .matches(
      REP_IPV4_CSV,
      'DNS must be a comma-separated list of IPv4 addresses',
    ),
  // Test gateway to make sure it's in one of the host's networks
  gateway: yupIpv4().required(),
  networks: yup.lazy((nets) =>
    yup.object(buildYupDynamicObject(nets, hostNetSchema)),
  ),
});

export default hostNetInitSchema;
