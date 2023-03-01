import { FC } from 'react';

import Grid from '../Grid';
import InputWithRef from '../InputWithRef';
import OutlinedInputWithLabel from '../OutlinedInputWithLabel';

const CommonUpsInputGroup: FC<CommonUpsInputGroupProps> = ({
  previous: {
    hostName: previousHostName,
    ipAddress: previousIpAddress,
    upsName: previousUpsName,
  } = {},
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
                  id="common-ups-input-host-name"
                  label="Host name"
                  value={previousHostName}
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
                  id="common-ups-input-ip-address"
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
    <input
      hidden
      id="common-ups-input-ups-name"
      readOnly
      value={previousUpsName}
    />
  </>
);

export default CommonUpsInputGroup;
