import * as yup from 'yup';

import { hostNetworkRequestBodySchema } from './hostNetworkRb';
import { yupIpv4, yupLaxUuid } from '../../../yupCommons';

export const prepareNetworkParamsSchema = yup.object({
  hostUUID: yupLaxUuid().required(),
});

export const prepareNetworkRequestBodySchema = yup.object({
  dns: yup.string(),
  gateway: yupIpv4().required(),
  gatewayInterface: yup.string().required(),
  hostName: yup.string().required(),
  networks: yup.array(hostNetworkRequestBodySchema).required(),
});
