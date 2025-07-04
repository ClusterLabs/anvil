import * as yup from 'yup';

import { INPUT_ID_AI_PREFIX, INPUT_ID_AI_SEQUENCE } from '../inputIds';

const buildDuplicateTestConfig: <T = string>(
  existing: string[],
) => yup.TestConfig<T, yup.AnyObject> = (names) => ({
  exclusive: true,
  message: '${path} already exists',
  name: 'duplicate-name',
  test: (ignore, context) => {
    const { createError, parent } = context;

    const { [INPUT_ID_AI_PREFIX]: prefix, [INPUT_ID_AI_SEQUENCE]: sequence } =
      parent;

    const paddedSequence = String(sequence).padStart(2, '0');

    const name = `${prefix}-anvil-${paddedSequence}`;

    if (names.includes(name)) {
      return createError({
        message: `${name} already exists`,
      });
    }

    return true;
  },
});

export default buildDuplicateTestConfig;
