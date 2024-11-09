import * as yup from 'yup';

import { yupLaxMac, yupLaxUuid } from '../../../lib/yupCommons';

/* eslint-disable no-template-curly-in-string */

const buildAddInterfaceSchema = (detail: APIServerDetail) =>
  yup.object({
    bridge: yupLaxUuid().required(),
    mac: yupLaxMac().notOneOf(
      [
        ...detail.devices.interfaces.map<string>((iface) => iface.mac.address),
        ...Object.values(detail.host.bridges).map<string>(
          (bridge) => bridge.mac,
        ),
      ],
      '${path} already exists',
    ),
    model: yup.string().nullable(),
  });

export default buildAddInterfaceSchema;
