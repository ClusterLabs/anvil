/* eslint-disable default-param-last */

import { REP_DOMAIN } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';
import { InlineMonoText } from '../../components/Text';

/**
 * @deprecated
 */
const buildDomainTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onDomainTestFailure,
) => ({
  defaults: { ...defaults, onSuccess },
  isRequired,
  onFinishBatch,
  tests: [
    {
      test: testNotBlank,
    },
    {
      onFailure: (...args) => {
        onDomainTestFailure(
          <>
            {inputName} can only contain lowercase alphanumeric, hyphen (
            <InlineMonoText inheritColour text="-" />
            ), and dot (<InlineMonoText inheritColour text="." />) characters.
          </>,
          ...args,
        );
      },
      test: ({ compare, value }) =>
        (compare[0] as boolean) || REP_DOMAIN.test(value as string),
    },
  ],
});

export default buildDomainTestBatch;
