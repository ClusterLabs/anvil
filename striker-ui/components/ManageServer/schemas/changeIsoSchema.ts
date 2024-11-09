import * as yup from 'yup';

import { yupLaxUuid } from '../../../lib/yupCommons';

const changeIsoSchema = yup.object({
  file: yupLaxUuid().nullable(),
});

export default changeIsoSchema;
