import testNotBlank from './testNotBlank';
import { InlineMonoText } from '../../components/Text';

const buildPeacefulStringTestBatch: BuildInputTestBatchFunction = (
  inputName,
  onSuccess,
  { getValue } = {},
  onTestPeacefulStringFailureAppend,
) => ({
  defaults: { getValue, onSuccess },
  tests: [
    {
      onFailure: (...args) => {
        onTestPeacefulStringFailureAppend(
          <>
            {inputName} cannot contain single-quote (
            <InlineMonoText text="'" />
            ), double-quote (<InlineMonoText text='"' />
            ), slash (<InlineMonoText text="/" />
            ), backslash (<InlineMonoText text="\" />
            ), angle brackets (<InlineMonoText text="<>" />
            ), curly brackets (<InlineMonoText text="{}" />
            ).
          </>,
          ...args,
        );
      },
      test: ({ value }) => !/['"/\\><}{]/g.test(value as string),
    },
    { test: testNotBlank },
  ],
});

export default buildPeacefulStringTestBatch;
