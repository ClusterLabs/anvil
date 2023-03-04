import { ReactElement } from 'react';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';
import {
  buildIPAddressTestBatch,
  buildPeacefulStringTestBatch,
} from '../../lib/test_input';

const INPUT_ID_UPS_IP = 'common-ups-input-ip-address';
const INPUT_ID_UPS_NAME = 'common-ups-input-host-name';

const INPUT_LABEL_UPS_IP = 'IP address';
const INPUT_LABEL_UPS_NAME = 'Host name';

const CommonUpsInputGroup = <
  M extends {
    [K in typeof INPUT_ID_UPS_IP | typeof INPUT_ID_UPS_NAME]: string;
  },
>({
  formUtils: {
    buildFinishInputTestBatchFunction,
    buildInputFirstRenderFunction,
    msgSetters,
  },
  previous: { upsIPAddress: previousIpAddress, upsName: previousUpsName } = {},
}: CommonUpsInputGroupProps<M>): ReactElement => (
  <Grid
    columns={{ xs: 1, sm: 2 }}
    layout={{
      'common-ups-input-cell-host-name': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_UPS_NAME}
                label={INPUT_LABEL_UPS_NAME}
                value={previousUpsName}
              />
            }
            inputTestBatch={buildPeacefulStringTestBatch(
              INPUT_LABEL_UPS_NAME,
              () => {
                msgSetters[INPUT_ID_UPS_NAME]();
              },
              {
                onFinishBatch:
                  buildFinishInputTestBatchFunction(INPUT_ID_UPS_NAME),
              },
              (message) => {
                msgSetters[INPUT_ID_UPS_NAME]({
                  children: message,
                });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(INPUT_ID_UPS_NAME)}
            required
          />
        ),
      },
      'common-ups-input-cell-ip-address': {
        children: (
          <InputWithRef
            input={
              <OutlinedInputWithLabel
                id={INPUT_ID_UPS_IP}
                label={INPUT_LABEL_UPS_IP}
                value={previousIpAddress}
              />
            }
            inputTestBatch={buildIPAddressTestBatch(
              INPUT_LABEL_UPS_IP,
              () => {
                msgSetters[INPUT_ID_UPS_IP]();
              },
              {
                onFinishBatch:
                  buildFinishInputTestBatchFunction(INPUT_ID_UPS_IP),
              },
              (message) => {
                msgSetters[INPUT_ID_UPS_IP]({
                  children: message,
                });
              },
            )}
            onFirstRender={buildInputFirstRenderFunction(INPUT_ID_UPS_IP)}
            required
          />
        ),
      },
    }}
    spacing="1em"
  />
);

export {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_LABEL_UPS_IP,
  INPUT_LABEL_UPS_NAME,
};

export default CommonUpsInputGroup;
