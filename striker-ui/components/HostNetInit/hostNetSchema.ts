import * as yup from 'yup';

import { REP_UUID } from '../../lib/consts/REG_EXP_PATTERNS';

import { yupIpv4 } from '../../lib/yupMatches';

const hostNetSchema = yup.object({
  interfaces: yup
    .array()
    .of(yup.string())
    .length(2)
    .required()
    .test({
      name: 'atleast1',
      message: 'At least 1 network interface is required',
      test: (list) => list.some((value = '') => REP_UUID.test(value)),
    }),
  ip: yupIpv4().required(),
  sequence: yup.number().required(),
  subnetMask: yupIpv4().required(),
  type: yup.string().oneOf(['bcn', 'ifn', 'mn', 'sn']),
});

export default hostNetSchema;
