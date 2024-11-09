import * as yup from 'yup';

import { REP_IPV4, REP_MAC, REP_UUID } from './consts';

export const yupLaxMac = () =>
  yup.string().matches(REP_MAC, {
    message: '${path} must be a valid MAC address',
  });

export const yupLaxUuid = () =>
  yup.string().matches(REP_UUID, {
    message: '${path} must be a valid UUID',
  });

export const yupIpv4 = () =>
  yup.string().matches(REP_IPV4, {
    message: '${path} must be a valid IPv4 address',
  });
