import { FC } from 'react';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';

const INPUT_ID_UPS_IP = 'common-ups-input-ip-address';
const INPUT_ID_UPS_NAME = 'common-ups-input-host-name';

const CommonUpsInputGroup: FC<CommonUpsInputGroupProps> = ({
  previous: { upsIPAddress: previousIpAddress, upsName: previousUpsName } = {},
}) => (
  <>
    <Grid
      columns={{ xs: 1, sm: 2 }}
      layout={{
        'common-ups-input-cell-host-name': {
          children: (
            <InputWithRef
              input={
                <OutlinedInputWithLabel
                  id={INPUT_ID_UPS_NAME}
                  label="Host name"
                  value={previousUpsName}
                />
              }
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
                  label="IP address"
                  value={previousIpAddress}
                />
              }
              required
            />
          ),
        },
      }}
      spacing="1em"
    />
  </>
);

export { INPUT_ID_UPS_IP, INPUT_ID_UPS_NAME };

export default CommonUpsInputGroup;
