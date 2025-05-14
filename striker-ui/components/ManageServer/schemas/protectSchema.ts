import * as yup from 'yup';

import { yupLaxUuid } from '../../../lib/yupCommons';

const protectSchema = yup.object({
  drUuid: yupLaxUuid().required('DR host is required.'),
  protocol: yup
    .string()
    .required()
    .oneOf(['long-throw', 'short-throw', 'sync']),
});

export default protectSchema;
