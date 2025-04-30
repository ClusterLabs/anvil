import * as yup from 'yup';

import { REP_IPV4, REP_LVM_UUID, REP_MAC, REP_UUID } from './consts';

export const yupDynamicObject = <S extends yup.Schema>(
  input: yup.AnyObject,
  schema: S,
): Record<string, S> =>
  Object.keys(input).reduce<Record<string, S>>(
    (previous, key) => ({
      ...previous,
      [key]: schema,
    }),
    {},
  );

export const yupIpv4 = () =>
  yup.string().matches(REP_IPV4, {
    message: '${path} must be a valid IPv4 address',
  });

export const yupLaxMac = () =>
  yup.string().matches(REP_MAC, {
    message: '${path} must be a valid MAC address',
  });

export const yupLaxUuid = () =>
  yup.string().matches(REP_UUID, {
    message: '${path} must be a valid UUID',
  });

export const yupLvmUuid = () =>
  yup.string().matches(REP_LVM_UUID, {
    message: '${path} must be a valid LVM internal UUID',
  });
