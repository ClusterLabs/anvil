import * as yup from 'yup';

import buildNameSchema from './buildNameSchema';

const buildFenceSchema = (
  uuid = '',
  fences: APIFenceOverviewList,
  agents: string[],
) =>
  yup.object({
    agent: yup.string().required().oneOf(agents),
    name: buildNameSchema(uuid, fences).required(),
  });

export default buildFenceSchema;
