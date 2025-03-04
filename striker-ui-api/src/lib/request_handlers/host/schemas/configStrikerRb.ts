import * as yup from 'yup';

import { hostNetworkRequestBodySchema } from './hostNetworkRb';
import { yupIpv4 } from '../../../yupCommons';

export const configStrikerRequestBodySchema = yup.object({
  adminPassword: yup.string().required(),
  domainName: yup.string().required(),
  hostName: yup.string().required(),
  hostNumber: yup.number().required().min(1),
  dns: yup.string(),
  gateway: yupIpv4().required(),
  gatewayInterface: yup.string().required(),
  networks: yup.array(hostNetworkRequestBodySchema).required(),
  organizationName: yup.string().required(),
  organizationPrefix: yup
    .string()
    .required()
    .matches(/^[a-z0-9]{1,5}$/, {
      message:
        '${path} can only contain 1 to 5 lowercase alphanumeric characters',
    }),
});
