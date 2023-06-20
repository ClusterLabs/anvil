import { ReactElement } from 'react';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildNumberTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';

const INPUT_ID_PREFIX_AN_ID = 'an-id-input';

const INPUT_ID_AI_DOMAIN = `${INPUT_ID_PREFIX_AN_ID}-domain`;
const INPUT_ID_AI_PREFIX = `${INPUT_ID_PREFIX_AN_ID}-prefix`;
const INPUT_ID_AI_SEQUENCE = `${INPUT_ID_PREFIX_AN_ID}-sequence`;

const INPUT_LABEL_AI_DOMAIN = 'Domain name';
const INPUT_LABEL_AI_PREFIX = 'Prefix';
const INPUT_LABEL_AI_SEQUENCE = 'Sequence';

const AnIdInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_AI_DOMAIN
      | typeof INPUT_ID_AI_PREFIX
      | typeof INPUT_ID_AI_SEQUENCE]: string;
  },
>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    setMessage,
  },
  previous: {
    domain: previousDomain,
    prefix: previousPrefix,
    sequence: previousSequence,
  } = {},
}: AnIdInputGroupProps<M>): ReactElement => (
  <Grid
    columns={{ xs: 1, sm: 2, md: 3 }}
    layout={{
      'an-id-input-cell-prefix': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_AI_PREFIX}
                label={INPUT_LABEL_AI_PREFIX}
                value={previousPrefix}
              />
            }
            inputTestBatch={buildPeacefulStringTestBatch(
              INPUT_LABEL_AI_PREFIX,
              () => {
                setMessage(INPUT_ID_AI_PREFIX);
              },
              {
                onFinishBatch:
                  buildFinishInputTestBatchFunction(INPUT_ID_AI_PREFIX),
              },
              (message) => {
                setMessage(INPUT_ID_AI_PREFIX, { children: message });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(INPUT_ID_AI_PREFIX)}
            required
          />
        ),
      },
      'an-id-input-cell-domain': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_AI_DOMAIN}
                label={INPUT_LABEL_AI_DOMAIN}
                value={previousDomain}
              />
            }
            inputTestBatch={buildPeacefulStringTestBatch(
              INPUT_LABEL_AI_DOMAIN,
              () => {
                setMessage(INPUT_ID_AI_DOMAIN);
              },
              {
                onFinishBatch:
                  buildFinishInputTestBatchFunction(INPUT_ID_AI_DOMAIN),
              },
              (message) => {
                setMessage(INPUT_ID_AI_DOMAIN, { children: message });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(INPUT_ID_AI_DOMAIN)}
            required
          />
        ),
      },
      'an-id-input-cell-sequence': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_AI_SEQUENCE}
                label={INPUT_LABEL_AI_SEQUENCE}
                value={previousSequence}
              />
            }
            inputTestBatch={buildNumberTestBatch(
              INPUT_LABEL_AI_SEQUENCE,
              () => {
                setMessage(INPUT_ID_AI_SEQUENCE);
              },
              {
                onFinishBatch:
                  buildFinishInputTestBatchFunction(INPUT_ID_AI_SEQUENCE),
              },
              (message) => {
                setMessage(INPUT_ID_AI_SEQUENCE, { children: message });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(INPUT_ID_AI_SEQUENCE)}
            required
            valueType="number"
          />
        ),
      },
    }}
    spacing="1em"
  />
);

export { INPUT_ID_AI_DOMAIN, INPUT_ID_AI_PREFIX, INPUT_ID_AI_SEQUENCE };

export default AnIdInputGroup;
