import * as yup from 'yup';

import { yupLaxMac } from '../../../lib/yupCommons';

const buildAddInterfaceSchema = (detail: APIServerDetail) =>
  yup.object({
    bridge: yup.string().required(),
    mac: yupLaxMac().notOneOf(
      [
        ...detail.devices.interfaces.map<string>((iface) => iface.mac.address),
        ...Object.values(detail.bridges).map<string>((bridge) => bridge.mac),
      ],
      '${path} already exists',
    ),
    model: yup.string().nullable(),
  });

export default buildAddInterfaceSchema;
