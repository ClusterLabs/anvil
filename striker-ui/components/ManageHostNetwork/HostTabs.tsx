import { Grid } from '@mui/material';
import { FC } from 'react';

import { DIVIDER } from '../../lib/consts/DEFAULT_THEME';

import Tab from '../Tab';
import Tabs from '../Tabs';
import { BodyText, MonoText } from '../Text';

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
        const { hostConfigured, hostStatus, hostUUID, shortHostName } = host;

        return (
          <Tab
            key={`host-${hostUUID}`}
            label={
              <Grid columns={{ xs: 2 }} container spacing="1em">
                <Grid item xs={1}>
                  <MonoText noWrap>{shortHostName}</MonoText>
                </Grid>
                <Grid borderLeft={`thin solid ${DIVIDER}`} item xs={1}>
                  <BodyText noWrap>
                    {hostStatus}
                    {hostConfigured ? ', configured' : ''}
                  </BodyText>
                </Grid>
              </Grid>
            }
            sx={{ textAlign: 'left' }}
            value={hostUUID}
          />
        );
      })}
    </Tabs>
  );
};

export default HostTabs;
