import * as yup from 'yup';

import { yupLaxUuid } from '../../../lib/yupMatches';

const changeIsoSchema = yup.object({
  file: yupLaxUuid().nullable(),
});

export default changeIsoSchema;
