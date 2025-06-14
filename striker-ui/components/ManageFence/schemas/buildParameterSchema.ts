import * as yup from 'yup';

import requiredFenceParameter from '../requiredFenceParameter';

const numberTypes: FenceParameterType[] = ['integer', 'second'];

const buildParameterSchema = (id: string, parameter: APIFenceSpecParameter) => {
  const { content_type: type, options } = parameter;

  let schema: yup.Schema;

  if (type === 'boolean') {
    schema = yup.boolean();
  } else if (numberTypes.includes(type)) {
    schema = yup.number();
  } else {
    schema = yup.string();
  }

  if (requiredFenceParameter(id, parameter)) {
    schema = schema.required();
  }

  if (options) {
    schema = schema.oneOf(options);
  }

  return schema;
};

export default buildParameterSchema;
