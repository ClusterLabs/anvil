import Grid from '@mui/material/Grid2';

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
>(
  ...[props]: Parameters<React.FC<CommonUpsInputGroupProps<M>>>
): ReturnType<React.FC<CommonUpsInputGroupProps<M>>> => {
  const {
    formUtils: {
      buildFinishInputTestBatchFunction,
      buildInputFirstRenderFunction,
      buildInputUnmountFunction,
      setMessage,
    },
    previous: {
      upsIPAddress: previousIpAddress,
      upsName: previousUpsName,
    } = {},
  } = props;

  return (
    <Grid
      columns={{
        xs: 1,
        sm: 2,
      }}
      container
      spacing="1em"
      width="100%"
    >
      <Grid size="grow">
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
              setMessage(INPUT_ID_UPS_NAME);
            },
            {
              onFinishBatch:
                buildFinishInputTestBatchFunction(INPUT_ID_UPS_NAME),
            },
            (message) => {
              setMessage(INPUT_ID_UPS_NAME, { children: message });
            },
          )}
          onFirstRender={buildInputFirstRenderFunction(INPUT_ID_UPS_NAME)}
          onUnmount={buildInputUnmountFunction(INPUT_ID_UPS_NAME)}
          required
        />
      </Grid>
      <Grid size="grow">
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
              setMessage(INPUT_ID_UPS_IP);
            },
            {
              onFinishBatch: buildFinishInputTestBatchFunction(INPUT_ID_UPS_IP),
            },
            (message) => {
              setMessage(INPUT_ID_UPS_IP, { children: message });
            },
          )}
          onFirstRender={buildInputFirstRenderFunction(INPUT_ID_UPS_IP)}
          onUnmount={buildInputUnmountFunction(INPUT_ID_UPS_IP)}
          required
        />
      </Grid>
    </Grid>
  );
};

export {
  INPUT_ID_UPS_IP,
  INPUT_ID_UPS_NAME,
  INPUT_LABEL_UPS_IP,
  INPUT_LABEL_UPS_NAME,
};

export default CommonUpsInputGroup;
