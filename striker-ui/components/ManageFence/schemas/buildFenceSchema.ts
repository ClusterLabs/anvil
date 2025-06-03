import * as yup from 'yup';

import buildNameSchema from './buildNameSchema';
import buildParameterSchema from './buildParameterSchema';
import buildYupDynamicObject from '../../../lib/buildYupDynamicObject';

const buildFenceSchema = (
  uuid = '',
  fences: APIFenceOverviewList,
  template: APIFenceTemplate,
) => {
  const agents = Object.keys(template);

  return yup.object({
    agent: yup.string().required().oneOf(agents),
    name: buildNameSchema(uuid, fences).required(),
    parameters: yup.lazy((parameters, options) => {
      const { context } = options;

      const agent: string = context?.agent ?? '';

      const obj = buildYupDynamicObject(parameters, (id) => {
        const { [agent]: spec } = template;

        if (!spec) {
          return yup.object({
            value: yup.mixed(),
          });
        }

        const { [id]: parameter } = spec.parameters;

        const value = buildParameterSchema(id, parameter);

        return yup.object({
          value,
        });
      });

      return yup.object(obj);
    }),
  });
};

export default buildFenceSchema;
