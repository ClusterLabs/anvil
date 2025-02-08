import * as yup from 'yup';

import { buildNameSchema } from '../../ProvisionServer';

const buildRenameSchema = (
  detail: APIServerDetail,
  servers: APIServerOverviewList,
) =>
  yup.object({
    name: buildNameSchema(detail.uuid, servers),
  });

export default buildRenameSchema;
