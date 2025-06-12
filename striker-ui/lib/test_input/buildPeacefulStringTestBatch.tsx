/* eslint-disable default-param-last */

import { REP_PEACEFUL_STRING } from '../consts/REG_EXP_PATTERNS';

import testNotBlank from './testNotBlank';
import { InlineMonoText } from '../../components/Text';

/**
 * @deprecated
 */
const buildPeacefulStringTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { isRequired, onFinishBatch, ...defaults } = {},
  onTestPeacefulStringFailureAppend,
) => ({
  defaults: { ...defaults, onSuccess },
  isRequired,
  onFinishBatch,
  tests: [
    {
      /**
       * Not-blank test ensures no unnecessary error message is provided when
       * input is not (yet) filled.
       */
      test: testNotBlank,
    },
    {
      onFailure: (...args) => {
        onTestPeacefulStringFailureAppend(
          <>
            {inputName} cannot contain single-quote (
            <InlineMonoText inheritColour text="'" />
            ), double-quote (<InlineMonoText inheritColour text='"' />
            ), slash (<InlineMonoText inheritColour text="/" />
            ), backslash (<InlineMonoText inheritColour text="\" />
            ), angle brackets (<InlineMonoText inheritColour text="<>" />
            ), curly brackets (<InlineMonoText inheritColour text="{}" />
            ).
          </>,
          ...args,
        );
      },
      test: ({ value }) => REP_PEACEFUL_STRING.test(value as string),
    },
  ],
});

export default buildPeacefulStringTestBatch;
