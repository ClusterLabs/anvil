import * as yup from 'yup';

import buildYupDynamicObject from '../../lib/buildYupDynamicObject';
import { yupLaxUuid } from '../../lib/yupMatches';

const fileLocationSchema = yup.object({ active: yup.boolean().required() });

const fileLocationAnvilSchema = yup.lazy((anvils) =>
  yup.object(buildYupDynamicObject(anvils, fileLocationSchema)),
);

const fileLocationDrHostSchema = yup.lazy((drHosts) =>
  yup.object(buildYupDynamicObject(drHosts, fileLocationSchema)),
);

const fileSchema = yup.object({
  locations: yup.object({
    anvils: fileLocationAnvilSchema,
    drHosts: fileLocationDrHostSchema,
  }),
  name: yup.string().required(),
  type: yup.string().oneOf(['iso', 'other', 'script']),
  uuid: yupLaxUuid().required(),
});

const fileListSchema = yup.lazy((files) =>
  yup.object(buildYupDynamicObject(files, fileSchema)),
);

export default fileListSchema;
