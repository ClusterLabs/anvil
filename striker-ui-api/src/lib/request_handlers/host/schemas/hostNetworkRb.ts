import * as yup from 'yup';

import { yupIpv4, yupLaxMac } from '../../../yupCommons';

const interfaceSchema = yup.object({
  mac: yupLaxMac().required(),
});

export const hostNetworkRequestBodySchema = yup.object({
  createBridge: yup.string().oneOf(['0', '1']),
  interfaces: yup.array(interfaceSchema.nullable().optional()).required(),
  ipAddress: yupIpv4().required(),
  sequence: yup.number().required().min(1),
  subnetMask: yupIpv4().required(),
  type: yup.string().required().oneOf(['bcn', 'ifn', 'sn', 'mn']),
});
