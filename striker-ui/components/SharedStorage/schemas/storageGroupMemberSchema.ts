import * as yup from 'yup';

import { yupLaxUuid } from '../../../lib/yupCommons';

const storageGroupMemberSchema = yup.object({
  vg: yupLaxUuid().required().nullable(),
});

export default storageGroupMemberSchema;
