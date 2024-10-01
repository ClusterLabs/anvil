import { Grid } from '@mui/material';
import { FC } from 'react';

import Tab from '../Tab';
import Tabs from '../Tabs';
import { BodyText } from '../Text';

const HostTabs: FC<HostTabsProps> = (props) => {
  const { list: hostValues, setValue, value } = props;

  if (hostValues.length === 0) {
    return <BodyText>No host(s) found.</BodyText>;
  }

  return (
    <Tabs
      centered
      onChange={(event, hostUuid) => {
        setValue(hostUuid);
      }}
      orientation="vertical"
      value={value}
    >
      {hostValues.map((host) => {
        const { anvil, hostStatus, hostUUID, shortHostName } = host;

        return (
          <Tab
            key={`host-${hostUUID}`}
            label={
              <Grid columns={4} container spacing={0}>
                <Grid item xs={1}>
                  <BodyText>{shortHostName}</BodyText>
                </Grid>
                <Grid item justifySelf="end" xs={1}>
                  <BodyText>{anvil ? `in ${anvil.name}` : 'is free'}</BodyText>
                </Grid>
                <Grid item xs={1}>
                  <BodyText>{hostStatus}</BodyText>
                </Grid>
              </Grid>
            }
            value={hostUUID}
          />
        );
      })}
    </Tabs>
  );
};

export default HostTabs;
