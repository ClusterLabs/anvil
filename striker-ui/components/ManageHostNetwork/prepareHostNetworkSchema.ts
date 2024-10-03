import * as yup from 'yup';

import { hostNetInitSchema } from '../HostNetInit';

const prepareHostNetworkSchema = yup.object({
  hostName: yup.string().required(),
  networkInit: hostNetInitSchema,
});

export default prepareHostNetworkSchema;
