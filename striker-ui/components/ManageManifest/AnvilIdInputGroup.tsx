import { ReactElement } from 'react';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildNumberTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';

const INPUT_ID_ANVIL_ID_DOMAIN = 'anvil-id-input-domain';
const INPUT_ID_ANVIL_ID_PREFIX = 'anvil-id-input-prefix';
const INPUT_ID_ANVIL_ID_SEQUENCE = 'anvil-id-input-sequence';

const INPUT_LABEL_ANVIL_ID_DOMAIN = 'Domain name';
const INPUT_LABEL_ANVIL_ID_PREFIX = 'Anvil! prefix';
const INPUT_LABEL_ANVIL_ID_SEQUENCE = 'Anvil! sequence';

const AnvilIdInputGroup = <
  M extends {
    [K in
      | typeof INPUT_ID_ANVIL_ID_DOMAIN
      | typeof INPUT_ID_ANVIL_ID_PREFIX
      | typeof INPUT_ID_ANVIL_ID_SEQUENCE]: string;
  },
>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
  },
  previous: {
    anvilIdDomain: previousDomain,
    anvilIdPrefix: previousPrefix,
    anvilIdSequence: previousSequence,
  } = {},
}: AnvilIdInputGroupProps<M>): ReactElement => (
  <Grid
    columns={{ xs: 1, sm: 2, md: 3 }}
    layout={{
      'anvil-id-input-cell-prefix': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_ANVIL_ID_PREFIX}
                label={INPUT_LABEL_ANVIL_ID_PREFIX}
                value={previousPrefix}
              />
            }
            inputTestBatch={buildPeacefulStringTestBatch(
              INPUT_LABEL_ANVIL_ID_PREFIX,
              () => {
                msgSetters[INPUT_ID_ANVIL_ID_PREFIX]();
              },
              {
                onFinishBatch: buildFinishInputTestBatchFunction(
                  INPUT_ID_ANVIL_ID_PREFIX,
                ),
              },
              (message) => {
                msgSetters[INPUT_ID_ANVIL_ID_PREFIX]({
                  children: message,
                });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(
              INPUT_ID_ANVIL_ID_PREFIX,
            )}
            required
          />
        ),
      },
      'anvil-id-input-cell-domain': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_ANVIL_ID_DOMAIN}
                label={INPUT_LABEL_ANVIL_ID_DOMAIN}
                value={previousDomain}
              />
            }
            inputTestBatch={buildPeacefulStringTestBatch(
              INPUT_LABEL_ANVIL_ID_DOMAIN,
              () => {
                msgSetters[INPUT_ID_ANVIL_ID_DOMAIN]();
              },
              {
                onFinishBatch: buildFinishInputTestBatchFunction(
                  INPUT_ID_ANVIL_ID_DOMAIN,
                ),
              },
              (message) => {
                msgSetters[INPUT_ID_ANVIL_ID_DOMAIN]({
                  children: message,
                });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(
              INPUT_ID_ANVIL_ID_DOMAIN,
            )}
            required
          />
        ),
      },
      'anvil-id-input-cell-sequence': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_ANVIL_ID_SEQUENCE}
                label={INPUT_LABEL_ANVIL_ID_SEQUENCE}
                value={previousSequence}
              />
            }
            inputTestBatch={buildNumberTestBatch(
              INPUT_LABEL_ANVIL_ID_SEQUENCE,
              () => {
                msgSetters[INPUT_ID_ANVIL_ID_SEQUENCE]();
              },
              {
                onFinishBatch: buildFinishInputTestBatchFunction(
                  INPUT_ID_ANVIL_ID_SEQUENCE,
                ),
              },
              (message) => {
                msgSetters[INPUT_ID_ANVIL_ID_SEQUENCE]({
                  children: message,
                });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(
              INPUT_ID_ANVIL_ID_SEQUENCE,
            )}
            required
            valueType="number"
          />
        ),
      },
    }}
    spacing="1em"
  />
);

export {
  INPUT_ID_ANVIL_ID_DOMAIN,
  INPUT_ID_ANVIL_ID_PREFIX,
  INPUT_ID_ANVIL_ID_SEQUENCE,
};

export default AnvilIdInputGroup;
