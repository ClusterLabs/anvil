import { REP_DOMAIN } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';
import { InlineMonoText } from '../../components/Text';

const buildDomainTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { compare: dCompare, getValue } = {},
  onDomainTestFailure,
) => ({
  defaults: { compare: dCompare, getValue, onSuccess },
  tests: [
    {
      onFailure: (...args) => {
        onDomainTestFailure(
          <>
            {inputName} can only contain lowercase alphanumeric, hyphen (
            <InlineMonoText text="-" />
            ), and dot (<InlineMonoText text="." />) characters.
          </>,
          ...args,
        );
      },
      test: ({ compare, value }) =>
        (compare[0] as boolean) || REP_DOMAIN.test(value as string),
    },
    { test: testNotBlank },
  ],
});

export default buildDomainTestBatch;
