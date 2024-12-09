import * as yup from 'yup';

import { REP_UUID } from '../../lib/consts/REG_EXP_PATTERNS';

import { yupIpv4 } from '../../lib/yupCommons';

const hasIface = (list: (string | undefined)[]) =>
  list.some((value = '') => REP_UUID.test(value));

const requiredWhenIface = <T extends yup.Schema>(schema: T) =>
  schema.when(['interfaces', 'required'], (values, s) => {
    const [list, required] = values;

    if (required || hasIface(list)) {
      return s.required();
    }

    return s;
  });

const hostNetSchema = yup.object({
  interfaces: yup
    .array()
    .of(yup.string())
    .length(2)
    .required()
    .when(['required'], (values, schema) => {
      const [required] = values;

      if (required) {
        return schema.test({
          name: 'atleast1',
          message: 'At least 1 network interface is required',
          test: hasIface,
        });
      }

      return schema;
    }),
  ip: requiredWhenIface(yupIpv4()),
  required: yup.bool(),
  sequence: requiredWhenIface(yup.number()),
  subnetMask: requiredWhenIface(yupIpv4()),
  type: yup.string().oneOf(['bcn', 'ifn', 'mn', 'sn']),
});

export default hostNetSchema;
