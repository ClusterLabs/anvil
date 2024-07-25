import * as yup from 'yup';

import buildYupDynamicObject from '../../lib/buildYupDynamicObject';
import { yupLaxUuid } from '../../lib/yupMatches';

const hostAnvilSchema = yup.object({
  name: yup.string().required(),
  uuid: yupLaxUuid().required(),
});

const hostSchema = yup.object({
  // Optional object, but its properties are restricted when it exists.
  anvil: yup.lazy((value) =>
    value !== undefined ? hostAnvilSchema : yup.mixed().optional(),
  ),
  // TODO: number and type should be required, but doing so produces errors.
  // This isn't broken, it's just logically incorrect; try to fix it later.
  number: yup.number(),
  type: yup.string(),
  uuid: yupLaxUuid().required(),
});

const runManifestSchema = yup.object({
  confirmPassword: yup
    .string()
    .oneOf([yup.ref('password')])
    .required(),
  description: yup.string().required(),
  hosts: yup.lazy((entries) =>
    yup.object(buildYupDynamicObject(entries, hostSchema)),
  ),
  password: yup.string().required(),
  reuseHosts: yup.boolean().when('hosts', (refs, field) => {
    const hosts = refs[0] as RunManifestFormikValues['hosts'];

    return Object.values(hosts).some((host) => Boolean(host.anvil))
      ? field.isTrue()
      : field.isFalse();
  }),
});

export default runManifestSchema;
